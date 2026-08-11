#include "opencv_candidate_detector.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <opencv2/imgproc.hpp>
#include <stdexcept>
#include <string>
#include <utility>

namespace sc::vision {
namespace {

constexpr double kPi = 3.14159265358979323846;

int odd_kernel(double requested, int minimum, int maximum) {
  auto value =
      std::clamp(static_cast<int>(std::round(requested)), minimum, maximum);
  if (value % 2 == 0) ++value;
  return std::min(value, maximum % 2 == 1 ? maximum : maximum - 1);
}

double mask_mean(const cv::Mat& image, const cv::Mat& mask) {
  const auto count = cv::countNonZero(mask);
  if (count == 0) return 0.0;
  return cv::mean(image, mask)[0];
}

cv::Mat disk_mask(const cv::Size& size, cv::Point center, int radius) {
  cv::Mat mask = cv::Mat::zeros(size, CV_8U);
  cv::circle(mask, center, std::max(1, radius), cv::Scalar(255), cv::FILLED,
             cv::LINE_AA);
  return mask;
}

cv::Mat annulus_mask(const cv::Size& size, cv::Point center, int inner_radius,
                     int outer_radius) {
  auto outer =
      disk_mask(size, center, std::max(inner_radius + 1, outer_radius));
  cv::circle(outer, center, std::max(1, inner_radius), cv::Scalar(0),
             cv::FILLED, cv::LINE_AA);
  return outer;
}

double overlap_fraction(const cv::Mat& first, const cv::Mat& second) {
  cv::Mat intersection;
  cv::bitwise_and(first, second, intersection);
  const auto denominator = cv::countNonZero(first);
  return denominator == 0
             ? 0.0
             : static_cast<double>(cv::countNonZero(intersection)) /
                   denominator;
}

cv::Mat normalize_local_illumination(const cv::Mat& gray,
                                     double expected_diameter_px) {
  cv::Mat illumination;
  const auto illumination_kernel =
      odd_kernel(expected_diameter_px * 8.0, 31, 301);
  cv::GaussianBlur(gray, illumination,
                   cv::Size(illumination_kernel, illumination_kernel), 0.0, 0.0,
                   cv::BORDER_REPLICATE);

  cv::Mat gray_float;
  cv::Mat illumination_float;
  gray.convertTo(gray_float, CV_32F);
  illumination.convertTo(illumination_float, CV_32F);
  cv::Mat normalized_float = gray_float - illumination_float + 128.0;
  cv::Mat normalized;
  normalized_float.convertTo(normalized, CV_8U);

  const auto tile = std::max(
      4, static_cast<int>(std::round(std::min(gray.cols, gray.rows) / 160.0)));
  const auto clahe = cv::createCLAHE(1.5, cv::Size(tile, tile));
  cv::Mat enhanced;
  clahe->apply(normalized, enhanced);
  return enhanced;
}

cv::Mat central_black_zone_mask(const cv::Mat& gray,
                                double expected_diameter_px) {
  cv::Mat smoothed;
  const auto kernel = odd_kernel(expected_diameter_px * 2.5, 11, 101);
  cv::GaussianBlur(gray, smoothed, cv::Size(kernel, kernel), 0.0, 0.0,
                   cv::BORDER_REPLICATE);
  cv::Mat thresholded;
  cv::threshold(smoothed, thresholded, 0, 255,
                cv::THRESH_BINARY_INV | cv::THRESH_OTSU);
  const auto morphology_radius =
      std::max(2, static_cast<int>(std::round(expected_diameter_px * 0.35)));
  cv::morphologyEx(thresholded, thresholded, cv::MORPH_CLOSE,
                   cv::getStructuringElement(
                       cv::MORPH_ELLIPSE, cv::Size(morphology_radius * 2 + 1,
                                                   morphology_radius * 2 + 1)));

  cv::Mat labels;
  cv::Mat stats;
  cv::Mat centroids;
  const auto count = cv::connectedComponentsWithStats(
      thresholded, labels, stats, centroids, 8, CV_32S);
  const cv::Point2d card_center(gray.cols / 2.0, gray.rows / 2.0);
  int selected_label = 0;
  double selected_score = -std::numeric_limits<double>::infinity();
  const auto minimum_area = gray.total() * 0.015;
  for (int label = 1; label < count; ++label) {
    const auto area = stats.at<int>(label, cv::CC_STAT_AREA);
    if (area < minimum_area) continue;
    const cv::Point2d component_center(centroids.at<double>(label, 0),
                                       centroids.at<double>(label, 1));
    const auto distance_to_center = cv::norm(component_center - card_center);
    const auto score = static_cast<double>(area) -
                       distance_to_center * std::min(gray.cols, gray.rows);
    if (score > selected_score) {
      selected_score = score;
      selected_label = label;
    }
  }

  cv::Mat mask = cv::Mat::zeros(gray.size(), CV_8U);
  if (selected_label != 0) {
    cv::compare(labels, selected_label, mask, cv::CMP_EQ);
  }
  return mask;
}

cv::Mat theoretical_ring_mask(const cv::Size& size,
                              const AnalyzeRequest& request) {
  cv::Mat mask = cv::Mat::zeros(size, CV_8U);
  const cv::Point center(size.width / 2, size.height / 2);
  const auto scale_x = (size.width - 1) / request.card_width_mm;
  const auto scale_y = (size.height - 1) / request.card_height_mm;
  const auto pixels_per_mm = std::min(scale_x, scale_y);
  const auto thickness = std::max(
      2, static_cast<int>(std::ceil(std::max(0.2, request.line_thickness_mm) *
                                    pixels_per_mm * 1.5)));
  for (const auto diameter_mm : request.ring_outer_diameters_mm) {
    if (!std::isfinite(diameter_mm) || diameter_mm <= 0.0) continue;
    const auto radius = std::max(
        1, static_cast<int>(std::round(diameter_mm * pixels_per_mm / 2.0)));
    if (radius >= std::max(size.width, size.height)) continue;
    cv::circle(mask, center, radius, cv::Scalar(255), thickness, cv::LINE_AA);
  }
  return mask;
}

cv::Mat large_uniform_patch_edge_mask(const cv::Mat& gray,
                                      double expected_diameter_px) {
  cv::Mat smoothed;
  const auto kernel = odd_kernel(expected_diameter_px * 1.5, 7, 61);
  cv::GaussianBlur(gray, smoothed, cv::Size(kernel, kernel), 0.0);
  cv::Mat edges;
  cv::Canny(smoothed, edges, 20, 60);
  std::vector<std::vector<cv::Point>> contours;
  cv::findContours(edges, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
  cv::Mat result = cv::Mat::zeros(gray.size(), CV_8U);
  const auto hole_area = kPi * std::pow(expected_diameter_px / 2.0, 2.0);
  const auto edge_thickness =
      std::max(2, static_cast<int>(std::round(expected_diameter_px * 0.20)));
  for (const auto& contour : contours) {
    const auto area = std::abs(cv::contourArea(contour));
    const auto rectangle = cv::boundingRect(contour);
    if (area < hole_area * 12.0 || std::max(rectangle.width, rectangle.height) <
                                       expected_diameter_px * 4.0) {
      continue;
    }
    cv::drawContours(result, std::vector<std::vector<cv::Point>>{contour}, -1,
                     cv::Scalar(255), edge_thickness, cv::LINE_AA);
  }
  return result;
}

int distance_transform_peak_count(const cv::Mat& component_mask) {
  cv::Mat distance_map;
  cv::distanceTransform(component_mask, distance_map, cv::DIST_L2, 5);
  double maximum = 0.0;
  cv::minMaxLoc(distance_map, nullptr, &maximum);
  if (maximum <= 0.0) return 0;
  cv::Mat local_maximum;
  cv::dilate(distance_map, local_maximum, cv::Mat());
  cv::Mat peaks;
  cv::compare(distance_map, local_maximum, peaks, cv::CMP_GE);
  cv::Mat strong;
  cv::threshold(distance_map, strong, maximum * 0.45, 255.0, cv::THRESH_BINARY);
  strong.convertTo(strong, CV_8U);
  cv::bitwise_and(peaks, strong, peaks);
  cv::morphologyEx(
      peaks, peaks, cv::MORPH_OPEN,
      cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3)));
  cv::Mat labels;
  return std::max(0, cv::connectedComponents(peaks, labels, 8, CV_32S) - 1);
}

struct EvidenceSample {
  double local_contrast = 0.0;
  double dark_core_contrast = 0.0;
  double fiber_edge_contrast = 0.0;
  double black_zone_fraction = 0.0;
  double ring_line_overlap_fraction = 0.0;
  double uniform_patch_edge_overlap_fraction = 0.0;
};

EvidenceSample sample_evidence(const cv::Mat& gray, const cv::Mat& normalized,
                               const cv::Mat& black_zone,
                               const cv::Mat& ring_mask,
                               const cv::Mat& patch_edge_mask, cv::Point center,
                               double expected_diameter_px) {
  const auto core_radius =
      std::max(2, static_cast<int>(std::round(expected_diameter_px * 0.28)));
  const auto fiber_inner =
      std::max(core_radius + 1,
               static_cast<int>(std::round(expected_diameter_px * 0.32)));
  const auto fiber_outer =
      std::max(fiber_inner + 1,
               static_cast<int>(std::round(expected_diameter_px * 0.62)));
  const auto background_inner =
      std::max(fiber_outer + 1,
               static_cast<int>(std::round(expected_diameter_px * 0.78)));
  const auto background_outer =
      std::max(background_inner + 1,
               static_cast<int>(std::round(expected_diameter_px * 1.18)));
  const auto core = disk_mask(gray.size(), center, core_radius);
  const auto fiber =
      annulus_mask(gray.size(), center, fiber_inner, fiber_outer);
  const auto background =
      annulus_mask(gray.size(), center, background_inner, background_outer);
  const auto core_mean = mask_mean(gray, core);
  const auto fiber_mean = mask_mean(gray, fiber);
  const auto background_mean = mask_mean(gray, background);
  const auto normalized_core = mask_mean(normalized, core);
  const auto normalized_background = mask_mean(normalized, background);

  EvidenceSample evidence;
  evidence.dark_core_contrast =
      std::max(0.0, (background_mean - core_mean) / 255.0);
  evidence.fiber_edge_contrast =
      std::max(0.0, (fiber_mean - background_mean) / 255.0);
  evidence.local_contrast =
      std::abs(normalized_background - normalized_core) / 255.0;
  evidence.black_zone_fraction = overlap_fraction(background, black_zone);
  evidence.ring_line_overlap_fraction = overlap_fraction(core, ring_mask);
  evidence.uniform_patch_edge_overlap_fraction =
      overlap_fraction(core, patch_edge_mask);
  return evidence;
}

bool point_inside(const cv::Point& point, const cv::Size& size) {
  return point.x >= 0 && point.x < size.width && point.y >= 0 &&
         point.y < size.height;
}

void append_reason_once(std::vector<std::string>& reasons,
                        const std::string& reason) {
  if (std::find(reasons.begin(), reasons.end(), reason) == reasons.end()) {
    reasons.push_back(reason);
  }
}

}  // namespace

std::map<std::string, double> CandidateDetectionDiagnostics::to_metrics()
    const {
  return {
      {"candidate_expected_diameter_px", expected_diameter_px},
      {"candidate_light_zone_threshold", light_zone_threshold},
      {"candidate_black_zone_threshold", black_zone_threshold},
      {"candidate_light_seed_pixel_count",
       static_cast<double>(light_seed_pixel_count)},
      {"candidate_black_seed_pixel_count",
       static_cast<double>(black_seed_pixel_count)},
      {"candidate_raw_component_count",
       static_cast<double>(raw_component_count)},
      {"candidate_rejected_too_small_count",
       static_cast<double>(rejected_too_small_count)},
      {"candidate_rejected_too_large_count",
       static_cast<double>(rejected_too_large_count)},
      {"candidate_rejected_geometry_count",
       static_cast<double>(rejected_geometry_count)},
      {"candidate_rejected_print_count",
       static_cast<double>(rejected_print_count)},
      {"candidate_rejected_weak_evidence_count",
       static_cast<double>(rejected_weak_evidence_count)},
      {"candidate_possible_overlap_count",
       static_cast<double>(possible_overlap_count)},
      {"candidate_light_zone_count",
       static_cast<double>(light_zone_candidate_count)},
      {"candidate_black_zone_count",
       static_cast<double>(black_zone_candidate_count)},
      {"candidate_high_confidence_count",
       static_cast<double>(high_confidence_count)},
      {"candidate_medium_confidence_count",
       static_cast<double>(medium_confidence_count)},
      {"candidate_low_confidence_count",
       static_cast<double>(low_confidence_count)},
  };
}

CandidateDetectionResult detect_candidates_on_canonical(
    const cv::Mat& canonical_gray, const AnalyzeRequest& request,
    const cv::Mat& canonical_to_source, const cv::Size& source_size) {
  if (canonical_gray.empty() || canonical_gray.type() != CV_8U ||
      source_size.width <= 0 || source_size.height <= 0) {
    throw std::invalid_argument(
        "Candidate detector received invalid image data");
  }
  const auto expected_pixels =
      request.projectile_diameter_mm * request.options.canonical_pixels_per_mm;
  if (!std::isfinite(expected_pixels) || expected_pixels < 2.0) {
    throw std::invalid_argument(
        "Candidate detector projectile scale is invalid");
  }

  const auto normalized =
      normalize_local_illumination(canonical_gray, expected_pixels);
  const auto black_zone =
      central_black_zone_mask(canonical_gray, expected_pixels);
  cv::Mat light_zone;
  cv::bitwise_not(black_zone, light_zone);
  const auto ring_mask = theoretical_ring_mask(canonical_gray.size(), request);
  const auto patch_edge_mask =
      large_uniform_patch_edge_mask(canonical_gray, expected_pixels);

  const auto feature_kernel_size = odd_kernel(expected_pixels * 1.55, 5, 81);
  const auto feature_kernel = cv::getStructuringElement(
      cv::MORPH_ELLIPSE, cv::Size(feature_kernel_size, feature_kernel_size));
  cv::Mat black_hat;
  cv::Mat top_hat;
  cv::morphologyEx(normalized, black_hat, cv::MORPH_BLACKHAT, feature_kernel);
  cv::morphologyEx(normalized, top_hat, cv::MORPH_TOPHAT, feature_kernel);

  cv::Scalar black_hat_mean;
  cv::Scalar black_hat_deviation;
  cv::meanStdDev(black_hat, black_hat_mean, black_hat_deviation, light_zone);
  cv::Scalar top_hat_mean;
  cv::Scalar top_hat_deviation;
  cv::meanStdDev(top_hat, top_hat_mean, top_hat_deviation, black_zone);
  const auto dark_threshold =
      std::clamp(black_hat_mean[0] + 1.25 * black_hat_deviation[0], 8.0, 64.0);
  const auto fiber_threshold =
      std::clamp(top_hat_mean[0] + 1.10 * top_hat_deviation[0], 7.0, 56.0);

  cv::Mat light_candidates;
  cv::threshold(black_hat, light_candidates, dark_threshold, 255,
                cv::THRESH_BINARY);
  // A black-hat response alone is brittle on soft, torn paper. Add a local
  // adaptive branch so a genuine dark core can still seed a low-confidence
  // proposal under uneven illumination. Later geometry/evidence filters still
  // decide whether it survives review.
  cv::Mat adaptive_dark;
  const auto adaptive_block = odd_kernel(expected_pixels * 4.5, 31, 151);
  cv::adaptiveThreshold(normalized, adaptive_dark, 255,
                        cv::ADAPTIVE_THRESH_GAUSSIAN_C,
                        cv::THRESH_BINARY_INV, adaptive_block, 5.0);
  cv::bitwise_or(light_candidates, adaptive_dark, light_candidates);
  cv::bitwise_and(light_candidates, light_zone, light_candidates);
  cv::Mat black_candidates;
  cv::threshold(top_hat, black_candidates, fiber_threshold, 255,
                cv::THRESH_BINARY);
  // In the black aiming area the paper fibres are normally brighter than the
  // background. A second local branch catches fibres that CLAHE/top-hat alone
  // suppresses, without treating a dark printed patch as a hole.
  cv::Mat adaptive_bright;
  cv::adaptiveThreshold(normalized, adaptive_bright, 255,
                        cv::ADAPTIVE_THRESH_GAUSSIAN_C,
                        cv::THRESH_BINARY, adaptive_block, -6.0);
  cv::bitwise_or(black_candidates, adaptive_bright, black_candidates);
  cv::bitwise_and(black_candidates, black_zone, black_candidates);
  const auto bridge_radius =
      std::max(1, static_cast<int>(std::round(expected_pixels * 0.10)));
  const auto bridge = cv::getStructuringElement(
      cv::MORPH_ELLIPSE,
      cv::Size(bridge_radius * 2 + 1, bridge_radius * 2 + 1));
  cv::morphologyEx(light_candidates, light_candidates, cv::MORPH_CLOSE, bridge);
  cv::morphologyEx(black_candidates, black_candidates, cv::MORPH_CLOSE, bridge);
  cv::dilate(black_candidates, black_candidates, bridge);
  cv::Mat combined;
  cv::bitwise_or(light_candidates, black_candidates, combined);
  cv::morphologyEx(
      combined, combined, cv::MORPH_OPEN,
      cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3)));

  std::vector<std::vector<cv::Point>> contours;
  cv::findContours(combined, contours, cv::RETR_EXTERNAL,
                   cv::CHAIN_APPROX_SIMPLE);
  CandidateDetectionResult output;
  output.diagnostics.expected_diameter_px = expected_pixels;
  output.diagnostics.light_zone_threshold = dark_threshold;
  output.diagnostics.black_zone_threshold = fiber_threshold;
  output.diagnostics.light_seed_pixel_count = cv::countNonZero(light_candidates);
  output.diagnostics.black_seed_pixel_count = cv::countNonZero(black_candidates);
  output.diagnostics.raw_component_count = contours.size();
  const auto expected_area = kPi * std::pow(expected_pixels / 2.0, 2.0);

  for (const auto& contour : contours) {
    const auto area = std::abs(cv::contourArea(contour));
    const auto perimeter = cv::arcLength(contour, true);
    if (area <= expected_area * 0.04 || perimeter <= 0.0) {
      ++output.diagnostics.rejected_too_small_count;
      ++output.diagnostics.rejected_geometry_count;
      continue;
    }
    const auto rectangle = cv::boundingRect(contour);
    const auto aspect =
        static_cast<double>(std::max(rectangle.width, rectangle.height)) /
        std::max(1, std::min(rectangle.width, rectangle.height));
    const auto equivalent_diameter = 2.0 * std::sqrt(area / kPi);
    const auto diameter_ratio = equivalent_diameter / expected_pixels;
    if (aspect > 4.0) {
      ++output.diagnostics.rejected_print_count;
      continue;
    }
    if (diameter_ratio < 0.38 || diameter_ratio > 3.25 ||
        std::max(rectangle.width, rectangle.height) > expected_pixels * 4.0) {
      if (diameter_ratio < 0.38) {
        ++output.diagnostics.rejected_too_small_count;
      } else {
        ++output.diagnostics.rejected_too_large_count;
      }
      ++output.diagnostics.rejected_geometry_count;
      continue;
    }
    const auto moments = cv::moments(contour);
    if (std::abs(moments.m00) < 1e-9) {
      ++output.diagnostics.rejected_geometry_count;
      continue;
    }
    const cv::Point center(
        static_cast<int>(std::round(moments.m10 / moments.m00)),
        static_cast<int>(std::round(moments.m01 / moments.m00)));
    if (!point_inside(center, canonical_gray.size())) {
      ++output.diagnostics.rejected_geometry_count;
      continue;
    }
    const auto circularity =
        std::clamp(4.0 * kPi * area / (perimeter * perimeter), 0.0, 1.0);
    std::vector<cv::Point> hull;
    cv::convexHull(contour, hull);
    const auto hull_perimeter = std::max(1e-9, cv::arcLength(hull, true));
    const auto raggedness =
        std::max(0.0, std::min(4.0, perimeter / hull_perimeter - 1.0));
    cv::Mat component = cv::Mat::zeros(canonical_gray.size(), CV_8U);
    cv::drawContours(component, std::vector<std::vector<cv::Point>>{contour},
                     -1, cv::Scalar(255), cv::FILLED);
    const auto evidence =
        sample_evidence(canonical_gray, normalized, black_zone, ring_mask,
                        patch_edge_mask, center, expected_pixels);
    const auto contour_ring_overlap = overlap_fraction(component, ring_mask);
    const auto contour_patch_overlap =
        overlap_fraction(component, patch_edge_mask);
    const auto in_black_zone = evidence.black_zone_fraction >= 0.50;
    const auto detector_response =
        mask_mean(in_black_zone ? top_hat : black_hat, component) / 255.0;

    const auto strong_dark_core = evidence.dark_core_contrast >= 0.075;
    const auto strong_fiber_edge = evidence.fiber_edge_contrast >= 0.045;
    const auto meaningful_contrast = evidence.local_contrast >= 0.040;
    const auto print_like =
        (aspect > 2.65 && circularity < 0.30) ||
        (contour_ring_overlap > 0.55 && circularity < 0.42 &&
         !strong_dark_core && !strong_fiber_edge) ||
        (contour_patch_overlap > 0.55 && !strong_dark_core &&
         !strong_fiber_edge);
    if (print_like) {
      ++output.diagnostics.rejected_print_count;
      continue;
    }
    const auto zone_signal = in_black_zone
                                 ? strong_fiber_edge || strong_dark_core
                                 : strong_dark_core || strong_fiber_edge;
    // Keep plausible but weaker responses as explicit low-confidence review
    // suggestions. Reject only when the local evidence and the morphology
    // response are both weak. This is deliberately recall-oriented because a
    // low-confidence candidate never counts without user confirmation.
    const auto morphology_signal = detector_response >= 0.030;
    if ((!zone_signal && !morphology_signal) ||
        (!meaningful_contrast && !strong_fiber_edge && !morphology_signal)) {
      ++output.diagnostics.rejected_weak_evidence_count;
      continue;
    }

    const auto peak_count = distance_transform_peak_count(component);
    const auto possible_overlap =
        diameter_ratio > 1.30 &&
        (peak_count >= 2 || area > expected_area * 1.45);

    CandidateImpact candidate;
    candidate.id = "candidate-" + std::to_string(output.candidates.size() + 1);
    std::vector<cv::Point2f> canonical_point = {cv::Point2f(
        static_cast<float>(center.x), static_cast<float>(center.y))};
    std::vector<cv::Point2f> source_point;
    cv::perspectiveTransform(canonical_point, source_point,
                             canonical_to_source);
    candidate.source_image_x_normalized =
        std::clamp(source_point[0].x / source_size.width, 0.0f, 1.0f);
    candidate.source_image_y_normalized =
        std::clamp(source_point[0].y / source_size.height, 0.0f, 1.0f);
    candidate.card_x_mm =
        center.x / static_cast<double>(std::max(1, canonical_gray.cols - 1)) *
            request.card_width_mm -
        request.card_width_mm / 2.0;
    candidate.card_y_mm =
        center.y / static_cast<double>(std::max(1, canonical_gray.rows - 1)) *
            request.card_height_mm -
        request.card_height_mm / 2.0;
    candidate.estimated_diameter_mm =
        equivalent_diameter / request.options.canonical_pixels_per_mm;
    candidate.evidence.local_contrast = evidence.local_contrast;
    candidate.evidence.dark_core_contrast = evidence.dark_core_contrast;
    candidate.evidence.fiber_edge_contrast = evidence.fiber_edge_contrast;
    candidate.evidence.diameter_ratio = diameter_ratio;
    candidate.evidence.circularity = circularity;
    candidate.evidence.raggedness = raggedness;
    candidate.evidence.ring_line_overlap_fraction = contour_ring_overlap;
    candidate.evidence.uniform_patch_edge_overlap_fraction =
        contour_patch_overlap;
    candidate.evidence.black_zone_fraction = evidence.black_zone_fraction;
    candidate.evidence.detector_response = detector_response;
    candidate.evidence.distance_transform_peak_count = peak_count;
    candidate.evidence.possible_overlap = possible_overlap;
    candidate.evidence.zone = in_black_zone ? "black" : "light";

    if (meaningful_contrast) {
      append_reason_once(candidate.reasons, "localContrast");
    }
    if (strong_dark_core) {
      append_reason_once(candidate.reasons, "darkCore");
    }
    if (strong_fiber_edge) {
      append_reason_once(candidate.reasons, "fiberEdge");
    }
    if (diameter_ratio >= 0.70 && diameter_ratio <= 1.35) {
      append_reason_once(candidate.reasons, "diameterMatchesProjectile");
    }
    if (in_black_zone && evidence.local_contrast < 0.075) {
      append_reason_once(candidate.reasons, "lowContrastBlackZone");
    }
    if (possible_overlap) {
      append_reason_once(candidate.reasons, "geometryUnverified");
      ++output.diagnostics.possible_overlap_count;
    }
    if (candidate.reasons.empty()) {
      append_reason_once(candidate.reasons, "geometryUnverified");
    }

    auto evidence_score = 0;
    evidence_score += strong_dark_core ? 2 : 0;
    evidence_score += strong_fiber_edge ? 2 : 0;
    evidence_score += meaningful_contrast ? 1 : 0;
    evidence_score += detector_response >= 0.075 ? 2
                      : detector_response >= 0.040 ? 1
                                                   : 0;
    evidence_score += diameter_ratio >= 0.72 && diameter_ratio <= 1.32 ? 2 : 0;
    evidence_score += circularity >= 0.55 ? 2 : circularity >= 0.32 ? 1 : 0;
    evidence_score -= contour_ring_overlap > 0.40 ? 1 : 0;
    evidence_score -= contour_patch_overlap > 0.40 ? 1 : 0;
    evidence_score -= possible_overlap ? 2 : 0;
    candidate.confidence = evidence_score >= 7   ? ConfidenceBand::high
                           : evidence_score >= 4 ? ConfidenceBand::medium
                                                 : ConfidenceBand::low;
    if (candidate.confidence == ConfidenceBand::high) {
      ++output.diagnostics.high_confidence_count;
    } else if (candidate.confidence == ConfidenceBand::medium) {
      ++output.diagnostics.medium_confidence_count;
    } else {
      ++output.diagnostics.low_confidence_count;
    }
    candidate.boundary_uncertainty_mm =
        std::max(0.5, std::abs(candidate.estimated_diameter_mm -
                               request.projectile_diameter_mm) /
                          2.0);
    const auto radius = std::hypot(candidate.card_x_mm, candidate.card_y_mm);
    for (const auto diameter : request.ring_outer_diameters_mm) {
      const auto distance_to_line = std::abs(radius - diameter / 2.0);
      if (distance_to_line <= request.projectile_diameter_mm / 2.0 +
                                  candidate.boundary_uncertainty_mm +
                                  request.line_thickness_mm / 2.0) {
        candidate.near_scoring_boundary = true;
        append_reason_once(candidate.reasons, "nearScoringLine");
        break;
      }
    }
    if (in_black_zone) {
      ++output.diagnostics.black_zone_candidate_count;
    } else {
      ++output.diagnostics.light_zone_candidate_count;
    }
    output.candidates.push_back(std::move(candidate));
    if (output.candidates.size() >= 200) break;
  }
  return output;
}

}  // namespace sc::vision
