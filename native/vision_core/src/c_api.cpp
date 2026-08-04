#include "vision_core/vision_core_c.h"

#include <cstdlib>
#include <cstring>
#include <exception>
#include <string>

#include "vision_core/vision_core.hpp"

namespace {

bool valid_request(const sc_vision_request_v1* request) {
  return request != nullptr && request->struct_size >= sizeof(*request) &&
         request->image_path_utf8 != nullptr &&
         request->image_path_utf8[0] != '\0' && request->card_width_mm > 0.0 &&
         request->card_height_mm > 0.0 &&
         request->projectile_diameter_mm > 0.0 &&
         request->minimum_long_side_px > 0 &&
         request->canonical_pixels_per_mm > 0.0;
}

bool copy_result(const std::string& source, sc_vision_owned_string* target) {
  auto* memory = static_cast<char*>(std::malloc(source.size() + 1));
  if (memory == nullptr) return false;
  std::memcpy(memory, source.data(), source.size());
  memory[source.size()] = '\0';
  target->data = memory;
  target->length = source.size();
  return true;
}

}  // namespace

extern "C" {

uint32_t sc_vision_abi_version(void) { return SC_VISION_ABI_VERSION; }

const char* sc_vision_engine_version(void) {
  return sc::vision::kEngineVersion;
}

uint32_t sc_vision_capabilities(void) { return sc::vision::capabilities(); }

sc_vision_return_code sc_vision_analyze_v1(
    const sc_vision_request_v1* request, sc_vision_owned_string* result_json) {
  if (result_json == nullptr) return SC_VISION_INVALID_ARGUMENT;
  result_json->data = nullptr;
  result_json->length = 0;
  if (!valid_request(request)) return SC_VISION_INVALID_ARGUMENT;
  try {
    sc::vision::AnalyzeRequest native_request;
    native_request.image_path = request->image_path_utf8;
    native_request.card_width_mm = request->card_width_mm;
    native_request.card_height_mm = request->card_height_mm;
    native_request.projectile_diameter_mm = request->projectile_diameter_mm;
    native_request.options.minimum_long_side_px = request->minimum_long_side_px;
    native_request.options.minimum_card_margin_fraction =
        request->minimum_card_margin_fraction;
    native_request.options.maximum_perspective_angle_degrees =
        request->maximum_perspective_angle_degrees;
    native_request.options.canonical_pixels_per_mm =
        request->canonical_pixels_per_mm;
    native_request.options.enable_candidate_detection =
        request->enable_candidate_detection != 0;
    const auto result = sc::vision::analyze(native_request).to_json();
    return copy_result(result, result_json) ? SC_VISION_OK
                                            : SC_VISION_INTERNAL_ERROR;
  } catch (const std::exception&) {
    return SC_VISION_INTERNAL_ERROR;
  }
}

void sc_vision_free_string(sc_vision_owned_string* value) {
  if (value == nullptr) return;
  std::free(value->data);
  value->data = nullptr;
  value->length = 0;
}

}  // extern "C"
