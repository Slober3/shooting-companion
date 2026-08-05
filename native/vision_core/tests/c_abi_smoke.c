#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "vision_core/vision_core_c.h"

int main(int argc, char** argv) {
  sc_vision_request_v1 request = {0};
  sc_vision_owned_string json = {0};
  sc_vision_return_code code;
  if (argc != 2) {
    fprintf(stderr, "fixture path required\n");
    return 2;
  }
  request.struct_size = sizeof(request);
  request.image_path_utf8 = argv[1];
  request.card_width_mm = 550.0;
  request.card_height_mm = 550.0;
  request.projectile_diameter_mm = 5.6;
  request.minimum_long_side_px = 8;
  request.minimum_card_margin_fraction = 0.02;
  request.maximum_perspective_angle_degrees = 35.0;
  request.canonical_pixels_per_mm = 4.0;
  request.enable_candidate_detection = 1;
  if (sc_vision_abi_version() != SC_VISION_ABI_VERSION) {
    fprintf(stderr, "ABI version mismatch\n");
    return 1;
  }
  code = sc_vision_analyze_v1(&request, &json);
  if (code != SC_VISION_OK || json.data == NULL || json.length == 0) {
    fprintf(stderr, "C ABI analysis failed\n");
    return 1;
  }
  if (strstr(json.data, "\"status\":\"unsupported\"") == NULL ||
      strstr(json.data, "\"candidateImpacts\":[]") == NULL) {
    fprintf(stderr, "C ABI returned dishonest fallback JSON\n");
    sc_vision_free_string(&json);
    return 1;
  }
  sc_vision_free_string(&json);
  if (json.data != NULL || json.length != 0) {
    fprintf(stderr, "C ABI free contract failed\n");
    return 1;
  }
  puts("vision_c_abi_smoke: passed");
  return 0;
}
