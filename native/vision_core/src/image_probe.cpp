#include "vision_core/vision_core.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iterator>
#include <numeric>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace sc::vision {
namespace {

std::optional<std::string> next_token(const std::vector<std::uint8_t>& bytes,
                                      std::size_t& offset) {
  while (offset < bytes.size()) {
    if (std::isspace(bytes[offset]) != 0) {
      ++offset;
      continue;
    }
    if (bytes[offset] == '#') {
      while (offset < bytes.size() && bytes[offset] != '\n') ++offset;
      continue;
    }
    break;
  }
  if (offset >= bytes.size()) return std::nullopt;
  const auto start = offset;
  while (offset < bytes.size() && std::isspace(bytes[offset]) == 0 &&
         bytes[offset] != '#') {
    ++offset;
  }
  return std::string(bytes.begin() + static_cast<std::ptrdiff_t>(start),
                     bytes.begin() + static_cast<std::ptrdiff_t>(offset));
}

ImageProbe probe_pgm(const std::vector<std::uint8_t>& bytes) {
  ImageProbe result;
  result.readable = true;
  std::size_t offset = 0;
  const auto magic = next_token(bytes, offset);
  const auto width_token = next_token(bytes, offset);
  const auto height_token = next_token(bytes, offset);
  const auto maximum_token = next_token(bytes, offset);
  if (!magic || !width_token || !height_token || !maximum_token) {
    result.error = "Incomplete PGM header";
    return result;
  }
  try {
    result.width = std::stoi(*width_token);
    result.height = std::stoi(*height_token);
    const auto maximum = std::stoi(*maximum_token);
    if (result.width <= 0 || result.height <= 0 || maximum <= 0 ||
        maximum > 65535) {
      result.error = "Invalid PGM dimensions or maximum value";
      return result;
    }
    GrayImage image;
    image.width = result.width;
    image.height = result.height;
    image.pixels.reserve(static_cast<std::size_t>(image.width * image.height));
    if (*magic == "P2") {
      for (int index = 0; index < image.width * image.height; ++index) {
        const auto token = next_token(bytes, offset);
        if (!token) {
          result.error = "PGM pixel data is truncated";
          return result;
        }
        const auto sample = std::stoi(*token);
        const auto scaled = std::clamp(sample * 255 / maximum, 0, 255);
        image.pixels.push_back(static_cast<std::uint8_t>(scaled));
      }
    } else if (*magic == "P5" && maximum <= 255) {
      if (offset < bytes.size() && std::isspace(bytes[offset]) != 0) ++offset;
      const auto count = static_cast<std::size_t>(image.width * image.height);
      if (offset + count > bytes.size()) {
        result.error = "PGM pixel data is truncated";
        return result;
      }
      image.pixels.assign(bytes.begin() + static_cast<std::ptrdiff_t>(offset),
                          bytes.begin() + static_cast<std::ptrdiff_t>(offset + count));
    } else {
      result.error = "Unsupported PGM encoding";
      return result;
    }
    result.recognized = true;
    result.format = "pgm";
    result.grayscale = std::move(image);
    return result;
  } catch (const std::exception&) {
    result.error = "Invalid numeric value in PGM";
    return result;
  }
}

std::uint32_t big_endian_u32(const std::vector<std::uint8_t>& bytes,
                             std::size_t offset) {
  return (static_cast<std::uint32_t>(bytes[offset]) << 24) |
         (static_cast<std::uint32_t>(bytes[offset + 1]) << 16) |
         (static_cast<std::uint32_t>(bytes[offset + 2]) << 8) |
         static_cast<std::uint32_t>(bytes[offset + 3]);
}

ImageProbe probe_png(const std::vector<std::uint8_t>& bytes) {
  ImageProbe result;
  result.readable = true;
  result.format = "png";
  if (bytes.size() < 24) {
    result.error = "PNG header is truncated";
    return result;
  }
  result.width = static_cast<int>(big_endian_u32(bytes, 16));
  result.height = static_cast<int>(big_endian_u32(bytes, 20));
  result.recognized = result.width > 0 && result.height > 0;
  if (!result.recognized) result.error = "PNG dimensions are invalid";
  return result;
}

bool is_start_of_frame(std::uint8_t marker) {
  return (marker >= 0xc0 && marker <= 0xc3) ||
         (marker >= 0xc5 && marker <= 0xc7) ||
         (marker >= 0xc9 && marker <= 0xcb) ||
         (marker >= 0xcd && marker <= 0xcf);
}

ImageProbe probe_jpeg(const std::vector<std::uint8_t>& bytes) {
  ImageProbe result;
  result.readable = true;
  result.format = "jpeg";
  std::size_t offset = 2;
  while (offset + 4 < bytes.size()) {
    while (offset < bytes.size() && bytes[offset] != 0xff) ++offset;
    while (offset < bytes.size() && bytes[offset] == 0xff) ++offset;
    if (offset >= bytes.size()) break;
    const auto marker = bytes[offset++];
    if (marker == 0xd8 || marker == 0xd9 || (marker >= 0xd0 && marker <= 0xd7)) {
      continue;
    }
    if (offset + 1 >= bytes.size()) break;
    const auto length =
        (static_cast<std::size_t>(bytes[offset]) << 8) | bytes[offset + 1];
    if (length < 2 || offset + length > bytes.size()) break;
    if (is_start_of_frame(marker) && length >= 7) {
      result.height = (static_cast<int>(bytes[offset + 3]) << 8) |
                      static_cast<int>(bytes[offset + 4]);
      result.width = (static_cast<int>(bytes[offset + 5]) << 8) |
                     static_cast<int>(bytes[offset + 6]);
      result.recognized = result.width > 0 && result.height > 0;
      return result;
    }
    offset += length;
  }
  result.error = "JPEG dimensions could not be read";
  return result;
}

}  // namespace

ImageProbe probe_image(const std::string& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input) {
    ImageProbe result;
    result.error = "Image file could not be opened";
    return result;
  }
  const std::vector<std::uint8_t> bytes{
      std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>()};
  if (bytes.size() >= 2 && bytes[0] == 'P' &&
      (bytes[1] == '2' || bytes[1] == '5')) {
    return probe_pgm(bytes);
  }
  constexpr std::uint8_t png_signature[] = {0x89, 'P', 'N', 'G', 0x0d,
                                             0x0a, 0x1a, 0x0a};
  if (bytes.size() >= 8 &&
      std::equal(std::begin(png_signature), std::end(png_signature),
                 bytes.begin())) {
    return probe_png(bytes);
  }
  if (bytes.size() >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
    return probe_jpeg(bytes);
  }
  ImageProbe result;
  result.readable = true;
  result.error = "Unsupported image format";
  return result;
}

QualityAssessment assess_quality(const GrayImage& image,
                                 int minimum_long_side_px) {
  if (!image.valid()) {
    throw std::invalid_argument("A valid grayscale image is required");
  }
  QualityAssessment result;
  result.width_px = image.width;
  result.height_px = image.height;
  const auto count = static_cast<double>(image.pixels.size());
  const auto sum = std::accumulate(image.pixels.begin(), image.pixels.end(), 0.0);
  const auto mean = sum / count;
  auto squared = 0.0;
  std::size_t dark = 0;
  std::size_t bright = 0;
  for (const auto pixel : image.pixels) {
    squared += (pixel - mean) * (pixel - mean);
    if (pixel <= 5) ++dark;
    if (pixel >= 250) ++bright;
  }
  result.contrast_score = std::sqrt(squared / count);
  result.dark_clipped_fraction = static_cast<double>(dark) / count;
  result.bright_clipped_fraction = static_cast<double>(bright) / count;

  auto laplacian_sum = 0.0;
  auto laplacian_squared = 0.0;
  std::size_t laplacian_count = 0;
  for (int y = 1; y < image.height - 1; ++y) {
    for (int x = 1; x < image.width - 1; ++x) {
      const auto at = [&](int px, int py) {
        return static_cast<double>(
            image.pixels[static_cast<std::size_t>(py * image.width + px)]);
      };
      const auto value = 4.0 * at(x, y) - at(x - 1, y) - at(x + 1, y) -
                         at(x, y - 1) - at(x, y + 1);
      laplacian_sum += value;
      laplacian_squared += value * value;
      ++laplacian_count;
    }
  }
  if (laplacian_count > 0) {
    const auto laplacian_mean = laplacian_sum / laplacian_count;
    result.blur_score =
        laplacian_squared / laplacian_count - laplacian_mean * laplacian_mean;
  }

  const auto long_side = std::max(image.width, image.height);
  if (long_side < minimum_long_side_px) {
    result.issues.push_back({"resolutionTooLow", IssueSeverity::error,
                             "De lange beeldzijde is kleiner dan de ingestelde minimumresolutie.",
                             static_cast<double>(long_side),
                             static_cast<double>(minimum_long_side_px)});
  }
  if (*result.contrast_score < 20.0) {
    result.issues.push_back({"lowContrast", IssueSeverity::warning,
                             "Het grijsbeeld heeft weinig lokaal toonbereik.",
                             result.contrast_score, 20.0});
  }
  if (*result.dark_clipped_fraction > 0.20) {
    result.issues.push_back({"underexposed", IssueSeverity::warning,
                             "Een groot deel van het beeld is volledig donker.",
                             result.dark_clipped_fraction, 0.20});
  }
  if (*result.bright_clipped_fraction > 0.20) {
    result.issues.push_back({"overexposed", IssueSeverity::warning,
                             "Een groot deel van het beeld is volledig helder.",
                             result.bright_clipped_fraction, 0.20});
  }
  if (result.blur_score && *result.blur_score < 30.0) {
    result.issues.push_back({"blurred", IssueSeverity::warning,
                             "Het grijsbeeld bevat weinig scherpe randen.",
                             result.blur_score, 30.0});
  }
  const auto has_error = std::any_of(
      result.issues.begin(), result.issues.end(),
      [](const QualityIssue& issue) { return issue.severity == IssueSeverity::error; });
  result.status = has_error
                      ? QualityStatus::rejected
                      : (result.issues.empty() ? QualityStatus::accepted
                                               : QualityStatus::review);
  return result;
}

}  // namespace sc::vision
