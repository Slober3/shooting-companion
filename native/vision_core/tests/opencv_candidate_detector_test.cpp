#include "opencv_candidate_detector.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <opencv2/imgproc.hpp>
#include <stdexcept>
#include <string>

#include "vision_core/vision_core.hpp"

namespace {

void require(bool condition, const std::string& message) {
  if (!condition) throw std::runtime_error(message);
}

double distance(const sc::vision::CandidateImpact& candidate, double x,
                double y) {
  return std::hypot(candidate.card_x_mm - x, candidate.card_y_mm - y);
}

const sc::vision::CandidateImpact* find_near(
    const std::vector<sc::vision::CandidateImpact>& candidates,
    double card_x_mm, double card_y_mm, double tolerance_mm) {
  for (const auto& candidate : candidates) {
    if (distance(candidate, card_x_mm, card_y_mm) <= tolerance_mm) {
      return &candidate;
    }
  }
  return nullptr;
}

cv::Mat make_synthetic_card() {
  cv::Mat card(880, 880, CV_8U, cv::Scalar(225));
  const cv::Point center(440, 440);
  cv::circle(card, center, 180, cv::Scalar(35), cv::FILLED, cv::LINE_AA);
  for (const auto radius : {40, 120, 200, 280, 360}) {
    cv::circle(card, center, radius, cv::Scalar(90), 2, cv::LINE_AA);
  }

  // A long printed feature: it must not become a hole proposal.
  cv::rectangle(card, cv::Rect(90, 330, 100, 5), cv::Scalar(45), cv::FILLED);

  // A large, uniform patch. Its edge is intentionally high contrast, but it is
  // not an impact.
  cv::circle(card, center, 62, cv::Scalar(244), cv::FILLED, cv::LINE_AA);

  // Isolated hole in the light zone with a bright torn-paper edge.
  cv::circle(card, cv::Point(160, 160), 12, cv::Scalar(248), cv::FILLED,
             cv::LINE_AA);
  cv::circle(card, cv::Point(160, 160), 8, cv::Scalar(15), cv::FILLED,
             cv::LINE_AA);

  // Isolated hole in the black zone. The dark core alone blends into the
  // target, so the fibre ring must provide the decisive evidence.
  cv::circle(card, cv::Point(545, 440), 13, cv::Scalar(225), cv::FILLED,
             cv::LINE_AA);
  cv::circle(card, cv::Point(545, 440), 7, cv::Scalar(8), cv::FILLED,
             cv::LINE_AA);

  // Two visibly merged holes in the light zone. They may produce one proposal,
  // but it must be marked as a possible overlap, never as inferred
  // multiplicity.
  cv::circle(card, cv::Point(675, 185), 12, cv::Scalar(248), cv::FILLED,
             cv::LINE_AA);
  cv::circle(card, cv::Point(691, 185), 12, cv::Scalar(248), cv::FILLED,
             cv::LINE_AA);
  cv::circle(card, cv::Point(675, 185), 10, cv::Scalar(18), cv::FILLED,
             cv::LINE_AA);
  cv::circle(card, cv::Point(691, 185), 10, cv::Scalar(18), cv::FILLED,
             cv::LINE_AA);

  // Deterministic illumination gradient exercises local normalization.
  for (int row = 0; row < card.rows; ++row) {
    auto* pixels = card.ptr<std::uint8_t>(row);
    for (int column = 0; column < card.cols; ++column) {
      const auto adjustment = static_cast<int>(std::round(
          (column / static_cast<double>(card.cols - 1) - 0.5) * 32.0));
      pixels[column] = static_cast<std::uint8_t>(
          std::clamp(static_cast<int>(pixels[column]) + adjustment, 0, 255));
    }
  }
  return card;
}

cv::Mat make_ring_only_card() {
  cv::Mat card(880, 880, CV_8U, cv::Scalar(225));
  const cv::Point center(440, 440);
  cv::circle(card, center, 180, cv::Scalar(35), cv::FILLED, cv::LINE_AA);
  for (const auto radius : {40, 120, 200, 280, 360}) {
    cv::circle(card, center, radius, cv::Scalar(90), 2, cv::LINE_AA);
  }
  return card;
}

sc::vision::AnalyzeRequest make_request() {
  sc::vision::AnalyzeRequest request;
  request.card_width_mm = 220.0;
  request.card_height_mm = 220.0;
  request.projectile_diameter_mm = 5.0;
  request.line_thickness_mm = 0.5;
  request.ring_outer_diameters_mm = {20.0, 60.0, 100.0, 140.0, 180.0};
  request.options.canonical_pixels_per_mm = 4.0;
  request.options.enable_candidate_detection = true;
  return request;
}

void test_dual_zone_detection() {
  const auto card = make_synthetic_card();
  const auto request = make_request();
  const auto detection = sc::vision::detect_candidates_on_canonical(
      card, request, cv::Mat::eye(3, 3, CV_64F), card.size());

  const auto light = find_near(detection.candidates, -70.0, -70.0, 5.0);
  require(light != nullptr, "Light-zone impact was not detected");
  require(light->evidence.zone == "light",
          "Light-zone impact was classified in the wrong zone");
  require(light->evidence.dark_core_contrast > 0.05,
          "Light-zone dark-core evidence was not measured");

  const auto black = find_near(detection.candidates, 26.25, 0.0, 5.0);
  require(black != nullptr, "Black-zone impact was not detected");
  require(black->evidence.zone == "black",
          "Black-zone impact was classified in the wrong zone");
  require(black->evidence.fiber_edge_contrast > 0.03,
          "Black-zone fibre evidence was not measured");

  // The uniform sticker occupies the card centre. No proposal should be close
  // to its edge or centre in the absence of a real hole.
  require(find_near(detection.candidates, 0.0, 0.0, 12.0) == nullptr,
          "Uniform patch produced a false impact candidate");
  require(find_near(detection.candidates, -75.0, -27.5, 10.0) == nullptr,
          "Long printed feature produced a false impact candidate");
  require(detection.diagnostics.rejected_print_count > 0,
          "Synthetic print suppression was not exercised");
  require(detection.diagnostics.expected_diameter_px > 0.0,
          "Expected projectile diameter is absent from diagnostics");
  require(detection.diagnostics.light_seed_pixel_count > 0,
          "Light-zone detector produced no seed pixels");
  require(detection.diagnostics.black_seed_pixel_count > 0,
          "Black-zone detector produced no seed pixels");
  require(detection.diagnostics.high_confidence_count +
              detection.diagnostics.medium_confidence_count +
              detection.diagnostics.low_confidence_count ==
          detection.candidates.size(),
          "Confidence diagnostics do not match surviving proposals");
  for (const auto& candidate : detection.candidates) {
    require(std::isfinite(candidate.evidence.detector_response) &&
                candidate.evidence.detector_response >= 0.0,
            "Candidate detector response is invalid");
  }
}

void test_ring_only_card_has_no_proposals() {
  const auto card = make_ring_only_card();
  const auto request = make_request();
  const auto detection = sc::vision::detect_candidates_on_canonical(
      card, request, cv::Mat::eye(3, 3, CV_64F), card.size());
  require(detection.candidates.empty(),
          "Clean ring-only card produced false impact proposals");
  require(detection.diagnostics.raw_component_count ==
              detection.diagnostics.rejected_too_small_count +
                  detection.diagnostics.rejected_too_large_count +
                  detection.diagnostics.rejected_geometry_count +
                  detection.diagnostics.rejected_print_count +
                  detection.diagnostics.rejected_weak_evidence_count,
          "Rejected component diagnostics do not explain an empty result");
}

void test_overlap_evidence_and_json() {
  const auto card = make_synthetic_card();
  const auto request = make_request();
  auto detection = sc::vision::detect_candidates_on_canonical(
      card, request, cv::Mat::eye(3, 3, CV_64F), card.size());
  const auto overlap = find_near(detection.candidates, 60.75, -63.75, 8.0);
  require(overlap != nullptr, "Merged visible holes were not proposed");
  require(overlap->evidence.possible_overlap,
          "Merged component lacks possible-overlap status");
  require(overlap->evidence.distance_transform_peak_count >= 1,
          "Overlap evidence did not contain distance-transform peaks");
  require(detection.diagnostics.possible_overlap_count >= 1,
          "Overlap diagnostic counter was not updated");

  sc::vision::AnalyzeResult result;
  result.candidates = std::move(detection.candidates);
  const auto json = result.to_json();
  require(json.find("\"detectorEvidence\"") != std::string::npos,
          "Structured detector evidence is absent from JSON");
  require(json.find("\"possibleOverlap\":true") != std::string::npos,
          "Overlap status is absent from JSON");
}

void test_determinism() {
  const auto card = make_synthetic_card();
  const auto request = make_request();
  const auto first = sc::vision::detect_candidates_on_canonical(
      card, request, cv::Mat::eye(3, 3, CV_64F), card.size());
  const auto second = sc::vision::detect_candidates_on_canonical(
      card, request, cv::Mat::eye(3, 3, CV_64F), card.size());
  require(first.candidates.size() == second.candidates.size(),
          "Detector output count is not deterministic");
  for (std::size_t index = 0; index < first.candidates.size(); ++index) {
    require(first.candidates[index].id == second.candidates[index].id,
            "Candidate identity is not deterministic");
    require(std::abs(first.candidates[index].card_x_mm -
                     second.candidates[index].card_x_mm) < 1e-12 &&
                std::abs(first.candidates[index].card_y_mm -
                         second.candidates[index].card_y_mm) < 1e-12,
            "Candidate coordinates are not deterministic");
  }
}

}  // namespace

int main() {
  try {
    test_dual_zone_detection();
    test_ring_only_card_has_no_proposals();
    test_overlap_evidence_and_json();
    test_determinism();
    std::cout << "opencv_candidate_detector_tests: all tests passed\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "opencv_candidate_detector_tests: " << error.what() << '\n';
    return 1;
  }
}
