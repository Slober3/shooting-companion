#include "vision_core/vision_core_c.h"

#include <atomic>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <new>
#include <string>

#include "vision_core/vision_core.hpp"

struct sc_vision_job {
  std::atomic_bool cancelled{false};
  sc::vision::AnalyzeRequest request;
};

namespace {

bool valid_common(const char* image_path, double card_width_mm,
                  double card_height_mm, double projectile_diameter_mm,
                  int32_t minimum_long_side_px,
                  double canonical_pixels_per_mm) {
  return image_path != nullptr && image_path[0] != '\0' &&
         card_width_mm > 0.0 && card_height_mm > 0.0 &&
         projectile_diameter_mm > 0.0 && minimum_long_side_px > 0 &&
         canonical_pixels_per_mm > 0.0;
}

bool valid_request(const sc_vision_request_v1* request) {
  return request != nullptr && request->struct_size >= sizeof(*request) &&
         valid_common(request->image_path_utf8, request->card_width_mm,
                      request->card_height_mm,
                      request->projectile_diameter_mm,
                      request->minimum_long_side_px,
                      request->canonical_pixels_per_mm);
}

bool valid_request(const sc_vision_request_v2* request) {
  if (request == nullptr || request->struct_size < sizeof(*request) ||
      !valid_common(request->image_path_utf8, request->card_width_mm,
                    request->card_height_mm,
                    request->projectile_diameter_mm,
                    request->minimum_long_side_px,
                    request->canonical_pixels_per_mm)) {
    return false;
  }
  if ((request->ring_count > 0 && request->rings == nullptr) ||
      (request->ordered_source_corner_count != 0 &&
       request->ordered_source_corner_count != 4) ||
      (request->ordered_source_corner_count > 0 &&
       request->ordered_source_corners_normalized_xy == nullptr)) {
    return false;
  }
  return true;
}

void set_options(sc::vision::AnalyzeRequest& target,
                 int32_t minimum_long_side_px,
                 double minimum_card_margin_fraction,
                 double maximum_perspective_angle_degrees,
                 double canonical_pixels_per_mm,
                 uint8_t enable_candidate_detection) {
  target.options.minimum_long_side_px = minimum_long_side_px;
  target.options.minimum_card_margin_fraction = minimum_card_margin_fraction;
  target.options.maximum_perspective_angle_degrees =
      maximum_perspective_angle_degrees;
  target.options.canonical_pixels_per_mm = canonical_pixels_per_mm;
  target.options.enable_candidate_detection =
      enable_candidate_detection != 0;
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

void reset_result(sc_vision_owned_string* result_json) {
  result_json->data = nullptr;
  result_json->length = 0;
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
  reset_result(result_json);
  if (!valid_request(request)) return SC_VISION_INVALID_ARGUMENT;
  try {
    sc::vision::AnalyzeRequest native_request;
    native_request.image_path = request->image_path_utf8;
    native_request.card_width_mm = request->card_width_mm;
    native_request.card_height_mm = request->card_height_mm;
    native_request.projectile_diameter_mm = request->projectile_diameter_mm;
    set_options(native_request, request->minimum_long_side_px,
                request->minimum_card_margin_fraction,
                request->maximum_perspective_angle_degrees,
                request->canonical_pixels_per_mm,
                request->enable_candidate_detection);
    const auto result = sc::vision::analyze(native_request).to_json();
    return copy_result(result, result_json) ? SC_VISION_OK
                                            : SC_VISION_INTERNAL_ERROR;
  } catch (const std::exception&) {
    return SC_VISION_INTERNAL_ERROR;
  }
}

sc_vision_return_code sc_vision_create_job_v2(
    const sc_vision_request_v2* request, sc_vision_job_handle* job) {
  if (job == nullptr) return SC_VISION_INVALID_ARGUMENT;
  *job = nullptr;
  if (!valid_request(request)) return SC_VISION_INVALID_ARGUMENT;
  try {
    auto* created = new sc_vision_job();
    created->request.job_id =
        request->job_id_utf8 == nullptr ? "" : request->job_id_utf8;
    created->request.image_path = request->image_path_utf8;
    created->request.card_width_mm = request->card_width_mm;
    created->request.card_height_mm = request->card_height_mm;
    created->request.projectile_diameter_mm =
        request->projectile_diameter_mm;
    created->request.line_thickness_mm = request->line_thickness_mm;
    created->request.cancellation_flag = &created->cancelled;
    set_options(created->request, request->minimum_long_side_px,
                request->minimum_card_margin_fraction,
                request->maximum_perspective_angle_degrees,
                request->canonical_pixels_per_mm,
                request->enable_candidate_detection);
    for (size_t index = 0; index < request->ring_count; ++index) {
      if (request->rings[index].outer_diameter_mm <= 0.0) {
        delete created;
        return SC_VISION_INVALID_ARGUMENT;
      }
      created->request.ring_outer_diameters_mm.push_back(
          request->rings[index].outer_diameter_mm);
    }
    if (request->ordered_source_corner_count == 4) {
      std::vector<sc::vision::Point> corners;
      corners.reserve(4);
      for (size_t index = 0; index < 4; ++index) {
        const auto x =
            request->ordered_source_corners_normalized_xy[index * 2];
        const auto y =
            request->ordered_source_corners_normalized_xy[index * 2 + 1];
        if (x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0) {
          delete created;
          return SC_VISION_INVALID_ARGUMENT;
        }
        corners.push_back({x, y});
      }
      created->request.manual_source_corners_normalized = std::move(corners);
    }
    *job = created;
    return SC_VISION_OK;
  } catch (const std::exception&) {
    return SC_VISION_INTERNAL_ERROR;
  }
}

sc_vision_return_code sc_vision_run_job_v2(
    sc_vision_job_handle job, sc_vision_owned_string* result_json) {
  if (job == nullptr || result_json == nullptr) {
    return SC_VISION_INVALID_ARGUMENT;
  }
  reset_result(result_json);
  if (job->cancelled.load()) return SC_VISION_CANCELLED;
  try {
    const auto result = sc::vision::analyze(job->request);
    if (job->cancelled.load()) return SC_VISION_CANCELLED;
    return copy_result(result.to_json(), result_json)
               ? SC_VISION_OK
               : SC_VISION_INTERNAL_ERROR;
  } catch (const std::exception&) {
    return job->cancelled.load() ? SC_VISION_CANCELLED
                                 : SC_VISION_INTERNAL_ERROR;
  }
}

void sc_vision_cancel_job_v2(sc_vision_job_handle job) {
  if (job != nullptr) job->cancelled.store(true);
}

void sc_vision_destroy_job_v2(sc_vision_job_handle job) { delete job; }

void sc_vision_free_string(sc_vision_owned_string* value) {
  if (value == nullptr) return;
  std::free(value->data);
  value->data = nullptr;
  value->length = 0;
}

}  // extern "C"
