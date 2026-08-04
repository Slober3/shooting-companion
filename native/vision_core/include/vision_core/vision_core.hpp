#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <vector>

namespace sc::vision {

inline constexpr std::uint32_t kAbiVersion = 1;
inline constexpr const char* kEngineVersion = "vision-core-0.1.0";

enum class AnalysisStatus { completed, unsupported, not_analyzed, failed };
enum class QualityStatus { accepted, review, rejected, not_analyzed, unsupported };
enum class RegistrationStatus {
  registered,
  manual_alignment_required,
  unsupported,
  not_analyzed,
  failed,
};
enum class Backend { geometry_only, open_cv };
enum class ConfidenceBand { low, medium, high };
enum class IssueSeverity { info, warning, error };

struct Point {
  double x = 0.0;
  double y = 0.0;
};

class Homography {
 public:
  explicit Homography(std::vector<double> row_major_matrix);

  static Homography from_point_pairs(const std::vector<Point>& source,
                                     const std::vector<Point>& destination);

  [[nodiscard]] Point apply(Point point) const;
  [[nodiscard]] const std::vector<double>& matrix() const noexcept;

 private:
  std::vector<double> matrix_;
};

struct GrayImage {
  int width = 0;
  int height = 0;
  std::vector<std::uint8_t> pixels;

  [[nodiscard]] bool valid() const noexcept;
};

struct ImageProbe {
  bool readable = false;
  bool recognized = false;
  int width = 0;
  int height = 0;
  std::optional<GrayImage> grayscale;
  std::string format;
  std::string error;
};

struct QualityIssue {
  std::string code;
  IssueSeverity severity = IssueSeverity::warning;
  std::string message;
  std::optional<double> measured_value;
  std::optional<double> threshold;
};

struct QualityAssessment {
  QualityStatus status = QualityStatus::not_analyzed;
  std::optional<int> width_px;
  std::optional<int> height_px;
  std::optional<double> blur_score;
  std::optional<double> contrast_score;
  std::optional<double> dark_clipped_fraction;
  std::optional<double> bright_clipped_fraction;
  std::vector<QualityIssue> issues;
};

struct RegistrationResult {
  RegistrationStatus status = RegistrationStatus::not_analyzed;
  std::vector<Point> ordered_normalized_corners;
  std::optional<std::vector<double>> homography_matrix;
  std::optional<double> reprojection_error_px;
  std::optional<double> estimated_perspective_angle_degrees;
  std::optional<std::string> algorithm_version;
};

struct CandidateImpact {
  std::string id;
  double image_x_normalized = 0.0;
  double image_y_normalized = 0.0;
  double x_mm = 0.0;
  double y_mm = 0.0;
  double estimated_diameter_mm = 0.0;
  ConfidenceBand confidence = ConfidenceBand::low;
  std::vector<std::string> reasons;
  double boundary_uncertainty_mm = 0.0;
};

struct Warning {
  std::string code;
  std::string message;
};

struct Provenance {
  Backend backend = Backend::geometry_only;
  std::vector<std::string> capabilities;
  std::map<std::string, std::string> algorithm_versions;
};

struct ProcessingOptions {
  int minimum_long_side_px = 2000;
  double minimum_card_margin_fraction = 0.02;
  double maximum_perspective_angle_degrees = 35.0;
  double canonical_pixels_per_mm = 4.0;
  bool enable_candidate_detection = true;
};

struct AnalyzeRequest {
  std::string image_path;
  double card_width_mm = 0.0;
  double card_height_mm = 0.0;
  double projectile_diameter_mm = 0.0;
  ProcessingOptions options;
};

struct AnalyzeResult {
  AnalysisStatus status = AnalysisStatus::not_analyzed;
  QualityAssessment quality;
  RegistrationResult registration;
  std::vector<CandidateImpact> candidates;
  std::vector<Warning> warnings;
  Provenance provenance;
  std::map<std::string, double> diagnostic_metrics;

  [[nodiscard]] std::string to_json() const;
};

[[nodiscard]] ImageProbe probe_image(const std::string& path);
[[nodiscard]] QualityAssessment assess_quality(const GrayImage& image,
                                                int minimum_long_side_px);
[[nodiscard]] AnalyzeResult analyze(const AnalyzeRequest& request);
[[nodiscard]] std::uint32_t capabilities() noexcept;

}  // namespace sc::vision
