#pragma once

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32) && defined(SC_VISION_BUILD_SHARED)
#define SC_VISION_API __declspec(dllexport)
#elif defined(_WIN32)
#define SC_VISION_API __declspec(dllimport)
#else
#define SC_VISION_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define SC_VISION_ABI_VERSION 2u

typedef enum sc_vision_return_code {
  SC_VISION_OK = 0,
  SC_VISION_INVALID_ARGUMENT = 1,
  SC_VISION_INTERNAL_ERROR = 2,
  SC_VISION_CANCELLED = 3
} sc_vision_return_code;

typedef enum sc_vision_capability {
  SC_VISION_CAP_IMAGE_METADATA = 1u << 0,
  SC_VISION_CAP_GRAYSCALE_QUALITY = 1u << 1,
  SC_VISION_CAP_OPENCV = 1u << 2,
  SC_VISION_CAP_REGISTRATION = 1u << 3,
  SC_VISION_CAP_CANDIDATES = 1u << 4
} sc_vision_capability;

typedef struct sc_vision_request_v1 {
  size_t struct_size;
  const char* image_path_utf8;
  double card_width_mm;
  double card_height_mm;
  double projectile_diameter_mm;
  int32_t minimum_long_side_px;
  double minimum_card_margin_fraction;
  double maximum_perspective_angle_degrees;
  double canonical_pixels_per_mm;
  uint8_t enable_candidate_detection;
} sc_vision_request_v1;

typedef struct sc_vision_ring_v2 {
  double outer_diameter_mm;
  int32_t score_value;
} sc_vision_ring_v2;

typedef struct sc_vision_request_v2 {
  size_t struct_size;
  const char* job_id_utf8;
  const char* image_path_utf8;
  double card_width_mm;
  double card_height_mm;
  double projectile_diameter_mm;
  double line_thickness_mm;
  const sc_vision_ring_v2* rings;
  size_t ring_count;
  const double* ordered_source_corners_normalized_xy;
  size_t ordered_source_corner_count;
  int32_t minimum_long_side_px;
  double minimum_card_margin_fraction;
  double maximum_perspective_angle_degrees;
  double canonical_pixels_per_mm;
  uint8_t enable_candidate_detection;
} sc_vision_request_v2;

typedef struct sc_vision_job* sc_vision_job_handle;

typedef struct sc_vision_owned_string {
  char* data;
  size_t length;
} sc_vision_owned_string;

SC_VISION_API uint32_t sc_vision_abi_version(void);
SC_VISION_API const char* sc_vision_engine_version(void);
SC_VISION_API uint32_t sc_vision_capabilities(void);

SC_VISION_API sc_vision_return_code sc_vision_analyze_v1(
    const sc_vision_request_v1* request,
    sc_vision_owned_string* result_json);

SC_VISION_API sc_vision_return_code sc_vision_create_job_v2(
    const sc_vision_request_v2* request,
    sc_vision_job_handle* job);

SC_VISION_API sc_vision_return_code sc_vision_run_job_v2(
    sc_vision_job_handle job,
    sc_vision_owned_string* result_json);

SC_VISION_API void sc_vision_cancel_job_v2(sc_vision_job_handle job);
SC_VISION_API void sc_vision_destroy_job_v2(sc_vision_job_handle job);

SC_VISION_API void sc_vision_free_string(sc_vision_owned_string* value);

#ifdef __cplusplus
}
#endif
