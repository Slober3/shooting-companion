#pragma once

#include <map>
#include <opencv2/core.hpp>
#include <vector>

#include "vision_core/vision_core.hpp"

namespace sc::vision {

struct CandidateDetectionDiagnostics {
  double expected_diameter_px = 0.0;
  double light_zone_threshold = 0.0;
  double black_zone_threshold = 0.0;
  std::size_t light_seed_pixel_count = 0;
  std::size_t black_seed_pixel_count = 0;
  std::size_t raw_component_count = 0;
  std::size_t rejected_too_small_count = 0;
  std::size_t rejected_too_large_count = 0;
  std::size_t rejected_geometry_count = 0;
  std::size_t rejected_print_count = 0;
  std::size_t rejected_weak_evidence_count = 0;
  std::size_t possible_overlap_count = 0;
  std::size_t light_zone_candidate_count = 0;
  std::size_t black_zone_candidate_count = 0;
  std::size_t high_confidence_count = 0;
  std::size_t medium_confidence_count = 0;
  std::size_t low_confidence_count = 0;

  [[nodiscard]] std::map<std::string, double> to_metrics() const;
};

struct CandidateDetectionResult {
  std::vector<CandidateImpact> candidates;
  CandidateDetectionDiagnostics diagnostics;
};

/// Detects visible impact candidates on a geometrically normalized card.
///
/// The detector deliberately does not infer calibre, multiplicity or score.
/// Large merged components are returned as a single, low-confidence candidate
/// with `possible_overlap` evidence so review remains a user decision.
[[nodiscard]] CandidateDetectionResult detect_candidates_on_canonical(
    const cv::Mat& canonical_gray, const AnalyzeRequest& request,
    const cv::Mat& canonical_to_source, const cv::Size& source_size);

}  // namespace sc::vision
