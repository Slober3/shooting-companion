#include "vision_core/vision_core.hpp"

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>

#include "opencv_backend.hpp"

#ifndef SC_VISION_HAS_OPENCV
#define SC_VISION_HAS_OPENCV 0
#endif

namespace sc::vision {
namespace {

std::string escape_json(const std::string& value) {
  std::ostringstream output;
  for (const auto character : value) {
    switch (character) {
      case '"':
        output << "\\\"";
        break;
      case '\\':
        output << "\\\\";
        break;
      case '\b':
        output << "\\b";
        break;
      case '\f':
        output << "\\f";
        break;
      case '\n':
        output << "\\n";
        break;
      case '\r':
        output << "\\r";
        break;
      case '\t':
        output << "\\t";
        break;
      default:
        if (static_cast<unsigned char>(character) < 0x20) {
          output << "\\u" << std::hex << std::setw(4) << std::setfill('0')
                 << static_cast<int>(static_cast<unsigned char>(character))
                 << std::dec;
        } else {
          output << character;
        }
    }
  }
  return output.str();
}

const char* name(AnalysisStatus status) {
  switch (status) {
    case AnalysisStatus::completed:
      return "completed";
    case AnalysisStatus::unsupported:
      return "unsupported";
    case AnalysisStatus::not_analyzed:
      return "notAnalyzed";
    case AnalysisStatus::failed:
      return "failed";
  }
  return "failed";
}

const char* name(QualityStatus status) {
  switch (status) {
    case QualityStatus::accepted:
      return "accepted";
    case QualityStatus::review:
      return "review";
    case QualityStatus::rejected:
      return "rejected";
    case QualityStatus::not_analyzed:
      return "notAnalyzed";
    case QualityStatus::unsupported:
      return "unsupported";
  }
  return "notAnalyzed";
}

const char* name(RegistrationStatus status) {
  switch (status) {
    case RegistrationStatus::registered:
      return "registered";
    case RegistrationStatus::manual_alignment_required:
      return "manualAlignmentRequired";
    case RegistrationStatus::unsupported:
      return "unsupported";
    case RegistrationStatus::not_analyzed:
      return "notAnalyzed";
    case RegistrationStatus::failed:
      return "failed";
  }
  return "notAnalyzed";
}

const char* name(Backend backend) {
  return backend == Backend::open_cv ? "openCv" : "geometryOnly";
}

const char* name(ConfidenceBand confidence) {
  switch (confidence) {
    case ConfidenceBand::low:
      return "low";
    case ConfidenceBand::medium:
      return "medium";
    case ConfidenceBand::high:
      return "high";
  }
  return "low";
}

const char* name(IssueSeverity severity) {
  switch (severity) {
    case IssueSeverity::info:
      return "info";
    case IssueSeverity::warning:
      return "warning";
    case IssueSeverity::error:
      return "error";
  }
  return "warning";
}

template <typename T>
void write_optional_number(std::ostringstream& output,
                           const std::optional<T>& value) {
  if (value) {
    output << std::setprecision(12) << *value;
  } else {
    output << "null";
  }
}

void write_string_array(std::ostringstream& output,
                        const std::vector<std::string>& values) {
  output << '[';
  for (std::size_t index = 0; index < values.size(); ++index) {
    if (index != 0) output << ',';
    output << '"' << escape_json(values[index]) << '"';
  }
  output << ']';
}

}  // namespace

AnalyzeResult analyze(const AnalyzeRequest& request) {
  if (request.image_path.empty() || request.card_width_mm <= 0.0 ||
      request.card_height_mm <= 0.0 || request.projectile_diameter_mm <= 0.0 ||
      request.options.minimum_long_side_px <= 0 ||
      request.options.canonical_pixels_per_mm <= 0.0) {
    throw std::invalid_argument("AnalyzeRequest contains invalid dimensions or path");
  }
  if (opencv_backend_available()) {
    return analyze_with_opencv(request);
  }

  AnalyzeResult result;
  result.status = AnalysisStatus::unsupported;
  result.provenance.backend = Backend::geometry_only;
  result.provenance.capabilities = {"imageMetadata", "grayscaleQuality"};
  result.provenance.algorithm_versions = {
      {"imageProbe", "image-probe-v1"}, {"quality", "quality-v1"}};
  result.registration.status = RegistrationStatus::unsupported;
  const auto probe = probe_image(request.image_path);
  if (!probe.readable) {
    result.status = AnalysisStatus::failed;
    result.quality.status = QualityStatus::not_analyzed;
    result.quality.issues.push_back(
        {"imageUnreadable", IssueSeverity::error,
         "Het beeldbestand kon niet worden geopend.", std::nullopt, std::nullopt});
    result.registration.status = RegistrationStatus::not_analyzed;
    result.warnings.push_back(
        {"imageUnreadable", "Het beeldbestand kon niet worden geopend."});
    return result;
  }
  if (!probe.recognized) {
    result.quality.status = QualityStatus::unsupported;
    result.quality.issues.push_back(
        {"unsupportedImageFormat", IssueSeverity::error,
         "Het beeldformaat wordt door deze build niet herkend.", std::nullopt,
         std::nullopt});
    result.warnings.push_back(
        {"unsupportedImageFormat",
         "Gebruik JPEG, PNG of PGM; volledige pixelanalyse vereist OpenCV."});
    return result;
  }

  result.diagnostic_metrics["image_width_px"] = probe.width;
  result.diagnostic_metrics["image_height_px"] = probe.height;
  if (probe.grayscale) {
    result.quality =
        assess_quality(*probe.grayscale, request.options.minimum_long_side_px);
  } else {
    result.quality.status = QualityStatus::not_analyzed;
    result.quality.width_px = probe.width;
    result.quality.height_px = probe.height;
    result.quality.issues.push_back(
        {"pixelStatisticsUnavailable", IssueSeverity::warning,
         "Afmetingen zijn gelezen, maar deze build kan de beeldpixels niet decoderen.",
         std::nullopt, std::nullopt});
  }
  result.warnings.push_back(
      {"openCvUnavailable",
       "Deze build bevat geen OpenCV-backend; registratie en trefferdetectie zijn niet uitgevoerd."});
  if (request.options.enable_candidate_detection) {
    result.warnings.push_back(
        {"candidateDetectionDisabled",
         "Trefferkandidaten zijn uitgeschakeld omdat geen gevalideerde beeldbackend beschikbaar is."});
  }
  return result;
}

std::uint32_t capabilities() noexcept {
  constexpr std::uint32_t metadata = 1u << 0;
  constexpr std::uint32_t grayscale_quality = 1u << 1;
#if SC_VISION_HAS_OPENCV
  constexpr std::uint32_t open_cv = 1u << 2;
  constexpr std::uint32_t registration = 1u << 3;
  constexpr std::uint32_t candidates = 1u << 4;
  return metadata | grayscale_quality | open_cv | registration | candidates;
#else
  return metadata | grayscale_quality;
#endif
}

std::string AnalyzeResult::to_json() const {
  std::ostringstream output;
  output << std::setprecision(12);
  output << "{\"schemaVersion\":1,\"status\":\"" << name(status)
         << "\",\"engineVersion\":\"" << kEngineVersion
         << "\",\"modelVersion\":null,";

  output << "\"provenance\":{\"backend\":\"" << name(provenance.backend)
         << "\",\"abiVersion\":" << kAbiVersion
         << ",\"engineVersion\":\"" << kEngineVersion
         << "\",\"capabilities\":";
  write_string_array(output, provenance.capabilities);
  output << ",\"algorithmVersions\":{";
  std::size_t algorithm_index = 0;
  for (const auto& [key, value] : provenance.algorithm_versions) {
    if (algorithm_index++ != 0) output << ',';
    output << '"' << escape_json(key) << "\":\"" << escape_json(value) << '"';
  }
  output << "},\"analyzedAtUtc\":null},";

  output << "\"registrationResult\":{\"status\":\""
         << name(registration.status) << "\",\"orderedNormalizedCorners\":[";
  for (std::size_t index = 0;
       index < registration.ordered_normalized_corners.size(); ++index) {
    if (index != 0) output << ',';
    const auto& point = registration.ordered_normalized_corners[index];
    output << "{\"x\":" << point.x << ",\"y\":" << point.y << '}';
  }
  output << "],\"homographyMatrix\":";
  if (registration.homography_matrix) {
    output << '[';
    for (std::size_t index = 0; index < registration.homography_matrix->size();
         ++index) {
      if (index != 0) output << ',';
      output << (*registration.homography_matrix)[index];
    }
    output << ']';
  } else {
    output << "null";
  }
  output << ",\"reprojectionErrorPx\":";
  write_optional_number(output, registration.reprojection_error_px);
  output << ",\"estimatedPerspectiveAngleDegrees\":";
  write_optional_number(output, registration.estimated_perspective_angle_degrees);
  output << ",\"algorithmVersion\":";
  if (registration.algorithm_version) {
    output << '"' << escape_json(*registration.algorithm_version) << '"';
  } else {
    output << "null";
  }
  output << "},";

  output << "\"qualityAssessment\":{\"status\":\"" << name(quality.status)
         << "\",\"widthPx\":";
  write_optional_number(output, quality.width_px);
  output << ",\"heightPx\":";
  write_optional_number(output, quality.height_px);
  output << ",\"blurScore\":";
  write_optional_number(output, quality.blur_score);
  output << ",\"contrastScore\":";
  write_optional_number(output, quality.contrast_score);
  output << ",\"darkClippedFraction\":";
  write_optional_number(output, quality.dark_clipped_fraction);
  output << ",\"brightClippedFraction\":";
  write_optional_number(output, quality.bright_clipped_fraction);
  output << ",\"issues\":[";
  for (std::size_t index = 0; index < quality.issues.size(); ++index) {
    if (index != 0) output << ',';
    const auto& issue = quality.issues[index];
    output << "{\"code\":\"" << escape_json(issue.code)
           << "\",\"severity\":\"" << name(issue.severity)
           << "\",\"message\":\"" << escape_json(issue.message)
           << "\",\"measuredValue\":";
    write_optional_number(output, issue.measured_value);
    output << ",\"threshold\":";
    write_optional_number(output, issue.threshold);
    output << '}';
  }
  output << "]},";

  output << "\"candidateImpacts\":[";
  for (std::size_t index = 0; index < candidates.size(); ++index) {
    if (index != 0) output << ',';
    const auto& candidate = candidates[index];
    output << "{\"id\":\"" << escape_json(candidate.id)
           << "\",\"imageXNormalized\":" << candidate.image_x_normalized
           << ",\"imageYNormalized\":" << candidate.image_y_normalized
           << ",\"xMm\":" << candidate.x_mm << ",\"yMm\":"
           << candidate.y_mm << ",\"estimatedDiameterMm\":"
           << candidate.estimated_diameter_mm << ",\"confidenceBand\":\""
           << name(candidate.confidence) << "\",\"reasons\":";
    write_string_array(output, candidate.reasons);
    output << ",\"boundaryUncertaintyMm\":"
           << candidate.boundary_uncertainty_mm << '}';
  }
  output << "],\"warnings\":[";
  for (std::size_t index = 0; index < warnings.size(); ++index) {
    if (index != 0) output << ',';
    output << "{\"code\":\"" << escape_json(warnings[index].code)
           << "\",\"message\":\"" << escape_json(warnings[index].message)
           << "\"}";
  }
  output << "],\"diagnosticMetrics\":{";
  std::size_t metric_index = 0;
  for (const auto& [key, value] : diagnostic_metrics) {
    if (metric_index++ != 0) output << ',';
    output << '"' << escape_json(key) << "\":" << value;
  }
  output << "}}";
  return output.str();
}

}  // namespace sc::vision
