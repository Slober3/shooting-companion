#include <cmath>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#include "vision_core/vision_core.hpp"
#include "vision_core/vision_core_c.h"

namespace {

void require(bool condition, const std::string& message) {
  if (!condition) throw std::runtime_error(message);
}

void test_homography() {
  const auto transform = sc::vision::Homography::from_point_pairs(
      {{0, 0}, {10, 0}, {10, 10}, {0, 10}},
      {{5, 8}, {25, 8}, {25, 28}, {5, 28}});
  const auto mapped = transform.apply({2.5, 7.5});
  require(std::abs(mapped.x - 10.0) < 1e-9, "Homography x mismatch");
  require(std::abs(mapped.y - 23.0) < 1e-9, "Homography y mismatch");
}

void test_quality() {
  sc::vision::GrayImage image;
  image.width = 8;
  image.height = 8;
  for (int y = 0; y < 8; ++y) {
    for (int x = 0; x < 8; ++x) {
      image.pixels.push_back((x + y) % 2 == 0 ? 0 : 255);
    }
  }
  const auto accepted = sc::vision::assess_quality(image, 8);
  require(accepted.status == sc::vision::QualityStatus::review,
          "Clipped checkerboard should require review");
  const auto rejected = sc::vision::assess_quality(image, 2000);
  require(rejected.status == sc::vision::QualityStatus::rejected,
          "Small image should be rejected");
}

void test_unsupported_analysis(const std::string& fixture) {
  sc::vision::AnalyzeRequest request;
  request.image_path = fixture;
  request.card_width_mm = 550;
  request.card_height_mm = 550;
  request.projectile_diameter_mm = 5.6;
  request.options.minimum_long_side_px = 8;
  const auto result = sc::vision::analyze(request);
  require(result.status == sc::vision::AnalysisStatus::unsupported,
          "Geometry-only build must report unsupported");
  require(result.candidates.empty(),
          "Unsupported analysis must never invent candidates");
  require(result.quality.width_px == 8 && result.quality.height_px == 8,
          "Fixture dimensions were not probed");
  const auto json = result.to_json();
  require(json.find("\"status\":\"unsupported\"") != std::string::npos,
          "Unsupported status missing from JSON");
  require(json.find("\"candidateImpacts\":[]") != std::string::npos,
          "Unsupported JSON exposed candidates");
}

void test_c_api(const std::string& fixture) {
  sc_vision_request_v1 request{};
  request.struct_size = sizeof(request);
  request.image_path_utf8 = fixture.c_str();
  request.card_width_mm = 550;
  request.card_height_mm = 550;
  request.projectile_diameter_mm = 5.6;
  request.minimum_long_side_px = 8;
  request.minimum_card_margin_fraction = 0.02;
  request.maximum_perspective_angle_degrees = 35;
  request.canonical_pixels_per_mm = 4;
  request.enable_candidate_detection = 1;
  sc_vision_owned_string json{};
  require(sc_vision_analyze_v1(&request, &json) == SC_VISION_OK,
          "C ABI analysis failed");
  require(json.data != nullptr && json.length > 0, "C ABI returned no JSON");
  require(std::string(json.data, json.length).find("openCvUnavailable") !=
              std::string::npos,
          "C ABI omitted capability warning");
  sc_vision_free_string(&json);
  require(json.data == nullptr && json.length == 0,
          "C ABI did not clear freed string");

  sc_vision_owned_string invalid_json{};
  require(sc_vision_analyze_v1(nullptr, &invalid_json) ==
              SC_VISION_INVALID_ARGUMENT,
          "C ABI accepted a null request");
  require(sc_vision_abi_version() == SC_VISION_ABI_VERSION,
          "C ABI version mismatch");
  require((sc_vision_capabilities() & SC_VISION_CAP_IMAGE_METADATA) != 0,
          "Metadata capability missing");
  require((sc_vision_capabilities() & SC_VISION_CAP_CANDIDATES) == 0,
          "Geometry-only build advertised candidate detection");
}

void test_missing_image() {
  sc::vision::AnalyzeRequest request;
  request.image_path = "this-file-does-not-exist.pgm";
  request.card_width_mm = 550;
  request.card_height_mm = 550;
  request.projectile_diameter_mm = 5.6;
  const auto result = sc::vision::analyze(request);
  require(result.status == sc::vision::AnalysisStatus::failed,
          "Missing input must return a structured failure");
  require(result.candidates.empty(), "Failed analysis exposed candidates");
}

}  // namespace

int main(int argc, char** argv) {
  try {
    if (argc != 2) throw std::invalid_argument("Fixture path required");
    test_homography();
    test_quality();
    test_unsupported_analysis(argv[1]);
    test_c_api(argv[1]);
    test_missing_image();
    std::cout << "vision_core_tests: all tests passed\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "vision_core_tests: " << error.what() << '\n';
    return 1;
  }
}
