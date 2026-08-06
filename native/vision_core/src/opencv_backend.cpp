#include "opencv_backend.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>
#include <vector>

#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

namespace sc::vision {
namespace {

constexpr double kPi = 3.14159265358979323846;

double distance(cv::Point2f first, cv::Point2f second) {
  const auto x = first.x - second.x;
  const auto y = first.y - second.y;
  return std::sqrt(x * x + y * y);
}

std::array<cv::Point2f, 4> order_corners(
    const std::vector<cv::Point>& polygon) {
  std::array<cv::Point2f, 4> ordered{};
  std::vector<cv::Point2f> points;
  for (const auto& point : polygon) {
    points.emplace_back(static_cast<float>(point.x), static_cast<float>(point.y));
  }
  ordered[0] = *std::min_element(points.begin(), points.end(),
                                 [](auto a, auto b) { return a.x + a.y < b.x + b.y; });
  ordered[2] = *std::max_element(points.begin(), points.end(),
                                 [](auto a, auto b) { return a.x + a.y < b.x + b.y; });
  ordered[1] = *std::max_element(points.begin(), points.end(),
                                 [](auto a, auto b) { return a.x - a.y < b.x - b.y; });
  ordered[3] = *std::min_element(points.begin(), points.end(),
                                 [](auto a, auto b) { return a.x - a.y < b.x - b.y; });
  return ordered;
}

std::optional<std::array<cv::Point2f, 4>> find_card(const cv::Mat& gray) {
  cv::Mat blurred;
  cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0.0);
  cv::Mat edges;
  cv::Canny(blurred, edges, 50, 150);
  cv::morphologyEx(edges, edges, cv::MORPH_CLOSE,
                   cv::getStructuringElement(cv::MORPH_RECT, cv::Size(7, 7)));
  std::vector<std::vector<cv::Point>> contours;
  cv::findContours(edges, contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
  const auto minimum_area = gray.cols * gray.rows * 0.20;
  double best_area = 0.0;
  std::optional<std::array<cv::Point2f, 4>> best;
  for (const auto& contour : contours) {
    const auto perimeter = cv::arcLength(contour, true);
    std::vector<cv::Point> polygon;
    cv::approxPolyDP(contour, polygon, 0.02 * perimeter, true);
    if (polygon.size() != 4 || !cv::isContourConvex(polygon)) continue;
    const auto area = std::abs(cv::contourArea(polygon));
    if (area >= minimum_area && area > best_area) {
      best_area = area;
      best = order_corners(polygon);
    }
  }
  return best;
}

double perspective_heuristic(const std::array<cv::Point2f, 4>& corners) {
  const std::array<double, 4> sides = {
      distance(corners[0], corners[1]), distance(corners[1], corners[2]),
      distance(corners[2], corners[3]), distance(corners[3], corners[0])};
  const auto [minimum, maximum] = std::minmax_element(sides.begin(), sides.end());
  if (*maximum <= 0.0) return 90.0;
  return std::acos(std::clamp(*minimum / *maximum, 0.0, 1.0)) * 180.0 / kPi;
}

GrayImage to_gray_image(const cv::Mat& gray) {
  GrayImage image;
  image.width = gray.cols;
  image.height = gray.rows;
  image.pixels.reserve(static_cast<std::size_t>(gray.cols * gray.rows));
  if (gray.isContinuous()) {
    image.pixels.assign(gray.data, gray.data + gray.total());
  } else {
    for (int row = 0; row < gray.rows; ++row) {
      image.pixels.insert(image.pixels.end(), gray.ptr<std::uint8_t>(row),
                          gray.ptr<std::uint8_t>(row) + gray.cols);
    }
  }
  return image;
}

bool rings_support_registration(const cv::Mat& canonical) {
  cv::Mat reduced;
  const auto scale = std::min(1.0, 1200.0 / std::max(canonical.cols, canonical.rows));
  cv::resize(canonical, reduced, cv::Size(), scale, scale, cv::INTER_AREA);
  cv::medianBlur(reduced, reduced, 5);
  std::vector<cv::Vec3f> circles;
  cv::HoughCircles(reduced, circles, cv::HOUGH_GRADIENT, 1.2, 12, 120, 40,
                   8, std::min(reduced.cols, reduced.rows) / 2);
  const cv::Point2f center(reduced.cols / 2.0f, reduced.rows / 2.0f);
  const auto center_tolerance = std::min(reduced.cols, reduced.rows) * 0.08;
  return std::count_if(circles.begin(), circles.end(), [&](const cv::Vec3f& circle) {
           return distance(cv::Point2f(circle[0], circle[1]), center) <=
                  center_tolerance;
         }) >= 3;
}

std::vector<CandidateImpact> detect_candidates(
    const cv::Mat& canonical, const AnalyzeRequest& request,
    const cv::Mat& canonical_to_source, const cv::Size& source_size) {
  cv::Mat binary;
  cv::adaptiveThreshold(canonical, binary, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C,
                        cv::THRESH_BINARY_INV, 31, 7);
  cv::morphologyEx(binary, binary, cv::MORPH_OPEN,
                   cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3)));
  std::vector<std::vector<cv::Point>> contours;
  cv::findContours(binary, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
  const auto expected_pixels = request.projectile_diameter_mm *
                               request.options.canonical_pixels_per_mm;
  std::vector<CandidateImpact> candidates;
  for (const auto& contour : contours) {
    const auto area = std::abs(cv::contourArea(contour));
    const auto perimeter = cv::arcLength(contour, true);
    if (area <= 0.0 || perimeter <= 0.0) continue;
    const auto equivalent_diameter = 2.0 * std::sqrt(area / kPi);
    if (equivalent_diameter < expected_pixels * 0.45 ||
        equivalent_diameter > expected_pixels * 1.80) {
      continue;
    }
    const auto circularity = 4.0 * kPi * area / (perimeter * perimeter);
    if (circularity < 0.15) continue;
    const auto moments = cv::moments(contour);
    if (std::abs(moments.m00) < 1e-9) continue;
    const auto x = moments.m10 / moments.m00;
    const auto y = moments.m01 / moments.m00;
    std::vector<cv::Point2f> canonical_point = {
        cv::Point2f(static_cast<float>(x), static_cast<float>(y))};
    std::vector<cv::Point2f> source_point;
    cv::perspectiveTransform(canonical_point, source_point,
                             canonical_to_source);
    CandidateImpact candidate;
    candidate.id = "candidate-" + std::to_string(candidates.size() + 1);
    candidate.source_image_x_normalized =
        std::clamp(source_point[0].x / source_size.width, 0.0f, 1.0f);
    candidate.source_image_y_normalized =
        std::clamp(source_point[0].y / source_size.height, 0.0f, 1.0f);
    candidate.card_x_mm =
        x / std::max(1, canonical.cols - 1) * request.card_width_mm -
        request.card_width_mm / 2.0;
    candidate.card_y_mm =
        y / std::max(1, canonical.rows - 1) * request.card_height_mm -
        request.card_height_mm / 2.0;
    candidate.estimated_diameter_mm =
        equivalent_diameter / request.options.canonical_pixels_per_mm;
    const auto diameter_ratio =
        candidate.estimated_diameter_mm / request.projectile_diameter_mm;
    candidate.confidence =
        circularity >= 0.72 && diameter_ratio >= 0.75 &&
                diameter_ratio <= 1.30
            ? ConfidenceBand::high
            : circularity >= 0.45 ? ConfidenceBand::medium
                                  : ConfidenceBand::low;
    candidate.reasons = {"localContrast", "diameterMatchesProjectile",
                         "darkCore"};
    candidate.boundary_uncertainty_mm = std::max(
        0.5, std::abs(candidate.estimated_diameter_mm -
                      request.projectile_diameter_mm) /
                 2.0);
    const auto radius =
        std::hypot(candidate.card_x_mm, candidate.card_y_mm);
    for (const auto diameter : request.ring_outer_diameters_mm) {
      const auto distance_to_line = std::abs(radius - diameter / 2.0);
      if (distance_to_line <= request.projectile_diameter_mm / 2.0 +
                                  candidate.boundary_uncertainty_mm +
                                  request.line_thickness_mm / 2.0) {
        candidate.near_scoring_boundary = true;
        candidate.reasons.push_back("nearScoringLine");
        break;
      }
    }
    candidates.push_back(std::move(candidate));
    if (candidates.size() >= 200) break;
  }
  return candidates;
}

}  // namespace

bool opencv_backend_available() noexcept { return true; }

AnalyzeResult analyze_with_opencv(const AnalyzeRequest& request) {
  AnalyzeResult result;
  result.provenance.backend = Backend::open_cv;
  result.provenance.capabilities = {"imageMetadata", "grayscaleQuality",
                                    "registration", "candidates"};
  result.provenance.algorithm_versions = {
      {"quality", "quality-v1"},
      {"registration", "contour-rings-v1"},
      {"candidates", "classical-candidates-v1"}};
  result.warnings.push_back(
      {"experimentalBackend",
       "Deze klassieke beeldbackend is experimenteel; alle kandidaten vereisen controle."});

  const auto source = cv::imread(request.image_path, cv::IMREAD_COLOR);
  if (source.empty()) {
    result.status = AnalysisStatus::failed;
    result.quality.status = QualityStatus::not_analyzed;
    result.registration.status = RegistrationStatus::not_analyzed;
    result.warnings.push_back(
        {"imageUnreadable", "Het beeldbestand kon niet worden gedecodeerd."});
    return result;
  }
  if (request.cancelled()) {
    throw std::runtime_error("Vision analysis cancelled");
  }
  cv::Mat gray;
  cv::cvtColor(source, gray, cv::COLOR_BGR2GRAY);
  result.quality =
      assess_quality(to_gray_image(gray), request.options.minimum_long_side_px);
  if (result.quality.status == QualityStatus::rejected) {
    result.status = AnalysisStatus::not_analyzed;
    result.registration.status = RegistrationStatus::not_analyzed;
    result.warnings.push_back(
        {"qualityRejected", "De kwaliteitscontrole blokkeerde verdere analyse."});
    return result;
  }
  if (request.cancelled()) {
    throw std::runtime_error("Vision analysis cancelled");
  }

  std::optional<std::array<cv::Point2f, 4>> corners;
  const auto uses_manual_alignment =
      request.manual_source_corners_normalized.has_value();
  if (uses_manual_alignment) {
    std::array<cv::Point2f, 4> manual{};
    for (std::size_t index = 0; index < 4; ++index) {
      const auto point = (*request.manual_source_corners_normalized)[index];
      manual[index] = cv::Point2f(
          static_cast<float>(point.x * source.cols),
          static_cast<float>(point.y * source.rows));
    }
    corners = manual;
  } else {
    corners = find_card(gray);
  }
  if (!corners) {
    result.status = AnalysisStatus::not_analyzed;
    result.registration.status = RegistrationStatus::manual_alignment_required;
    result.warnings.push_back(
        {"registrationFailed", "Geen betrouwbare kaartvierhoek gevonden; lijn handmatig uit."});
    return result;
  }
  const auto angle = perspective_heuristic(*corners);
  result.registration.estimated_perspective_angle_degrees = angle;
  if (!uses_manual_alignment &&
      angle > request.options.maximum_perspective_angle_degrees) {
    result.status = AnalysisStatus::not_analyzed;
    result.registration.status = RegistrationStatus::manual_alignment_required;
    result.warnings.push_back(
        {"registrationFailed", "De geschatte perspectiefhoek is te groot."});
    return result;
  }
  const auto width = std::clamp(
      static_cast<int>(std::round(request.card_width_mm *
                                  request.options.canonical_pixels_per_mm)),
      256, 4096);
  const auto height = std::clamp(
      static_cast<int>(std::round(request.card_height_mm *
                                  request.options.canonical_pixels_per_mm)),
      256, 4096);
  const std::array<cv::Point2f, 4> destination = {
      cv::Point2f(0, 0), cv::Point2f(static_cast<float>(width - 1), 0),
      cv::Point2f(static_cast<float>(width - 1), static_cast<float>(height - 1)),
      cv::Point2f(0, static_cast<float>(height - 1))};
  const std::vector<cv::Point2f> source_points(corners->begin(), corners->end());
  const std::vector<cv::Point2f> destination_points(destination.begin(),
                                                    destination.end());
  const cv::Mat transform =
      cv::getPerspectiveTransform(source_points, destination_points);
  const cv::Mat canonical_to_source = transform.inv();
  cv::Mat canonical;
  cv::warpPerspective(gray, canonical, transform, cv::Size(width, height));
  if (request.cancelled()) {
    throw std::runtime_error("Vision analysis cancelled");
  }
  if (!uses_manual_alignment && !rings_support_registration(canonical)) {
    result.status = AnalysisStatus::not_analyzed;
    result.registration.status = RegistrationStatus::manual_alignment_required;
    result.warnings.push_back(
        {"registrationFailed", "De kaartcontour werd gevonden maar de concentrische ringen bevestigen de registratie niet."});
    return result;
  }

  result.registration.status = RegistrationStatus::registered;
  result.registration.algorithm_version = uses_manual_alignment
                                              ? "manual-corners-v1"
                                              : "contour-rings-v2";
  result.registration.estimated_perspective_angle_degrees = angle;
  for (const auto& corner : *corners) {
    result.registration.ordered_source_corners_normalized.push_back(
        {corner.x / source.cols, corner.y / source.rows});
  }
  const std::vector<cv::Point2f> normalized_source_points = {
      {static_cast<float>((*corners)[0].x / source.cols),
       static_cast<float>((*corners)[0].y / source.rows)},
      {static_cast<float>((*corners)[1].x / source.cols),
       static_cast<float>((*corners)[1].y / source.rows)},
      {static_cast<float>((*corners)[2].x / source.cols),
       static_cast<float>((*corners)[2].y / source.rows)},
      {static_cast<float>((*corners)[3].x / source.cols),
       static_cast<float>((*corners)[3].y / source.rows)}};
  const std::vector<cv::Point2f> card_mm_points = {
      {static_cast<float>(-request.card_width_mm / 2.0),
       static_cast<float>(-request.card_height_mm / 2.0)},
      {static_cast<float>(request.card_width_mm / 2.0),
       static_cast<float>(-request.card_height_mm / 2.0)},
      {static_cast<float>(request.card_width_mm / 2.0),
       static_cast<float>(request.card_height_mm / 2.0)},
      {static_cast<float>(-request.card_width_mm / 2.0),
       static_cast<float>(request.card_height_mm / 2.0)}};
  const auto source_normalized_to_card_mm = cv::getPerspectiveTransform(
      normalized_source_points, card_mm_points);
  std::vector<double> matrix;
  matrix.reserve(9);
  for (int row = 0; row < 3; ++row) {
    for (int column = 0; column < 3; ++column) {
      matrix.push_back(
          source_normalized_to_card_mm.at<double>(row, column));
    }
  }
  result.registration.source_normalized_to_card_mm_homography =
      std::move(matrix);
  result.status = AnalysisStatus::completed;
  if (request.options.enable_candidate_detection) {
    if (request.cancelled()) {
      throw std::runtime_error("Vision analysis cancelled");
    }
    result.candidates = detect_candidates(canonical, request,
                                          canonical_to_source, source.size());
    result.warnings.push_back(
        {"candidatesRequireReview", "Bevestig, verplaats of verwijder iedere voorgestelde treffer handmatig."});
  } else {
    result.warnings.push_back(
        {"candidateDetectionDisabled", "Trefferdetectie is voor deze analyse uitgeschakeld."});
  }
  result.diagnostic_metrics["canonical_width_px"] = width;
  result.diagnostic_metrics["canonical_height_px"] = height;
  result.diagnostic_metrics["candidate_count"] = result.candidates.size();
  return result;
}

}  // namespace sc::vision
