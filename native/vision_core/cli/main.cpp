#include <cstdlib>
#include <exception>
#include <iostream>
#include <stdexcept>
#include <string>

#include "vision_core/vision_core.hpp"

namespace {

void usage() {
  std::cerr
      << "vision_cli analyze --image PATH --card-width-mm N "
         "--card-height-mm N --projectile-diameter-mm N [options]\n"
         "Options:\n"
         "  --minimum-long-side-px N\n"
         "  --pixels-per-mm N\n"
         "  --no-candidates\n"
         "  --capabilities\n"
         "  --version\n";
}

std::string require_value(int argc, char** argv, int& index) {
  if (++index >= argc) throw std::invalid_argument("Missing option value");
  return argv[index];
}

}  // namespace

int main(int argc, char** argv) {
  try {
    if (argc == 2 && std::string(argv[1]) == "--version") {
      std::cout << sc::vision::kEngineVersion << '\n';
      return 0;
    }
    if (argc == 2 && std::string(argv[1]) == "--capabilities") {
      std::cout << sc::vision::capabilities() << '\n';
      return 0;
    }
    if (argc < 2 || std::string(argv[1]) != "analyze") {
      usage();
      return 2;
    }
    sc::vision::AnalyzeRequest request;
    for (int index = 2; index < argc; ++index) {
      const std::string option(argv[index]);
      if (option == "--image") {
        request.image_path = require_value(argc, argv, index);
      } else if (option == "--card-width-mm") {
        request.card_width_mm = std::stod(require_value(argc, argv, index));
      } else if (option == "--card-height-mm") {
        request.card_height_mm = std::stod(require_value(argc, argv, index));
      } else if (option == "--projectile-diameter-mm") {
        request.projectile_diameter_mm =
            std::stod(require_value(argc, argv, index));
      } else if (option == "--minimum-long-side-px") {
        request.options.minimum_long_side_px =
            std::stoi(require_value(argc, argv, index));
      } else if (option == "--pixels-per-mm") {
        request.options.canonical_pixels_per_mm =
            std::stod(require_value(argc, argv, index));
      } else if (option == "--no-candidates") {
        request.options.enable_candidate_detection = false;
      } else {
        throw std::invalid_argument("Unknown option: " + option);
      }
    }
    const auto result = sc::vision::analyze(request);
    std::cout << result.to_json() << '\n';
    return result.status == sc::vision::AnalysisStatus::failed ? 3 : 0;
  } catch (const std::exception& error) {
    std::cerr << "vision_cli: " << error.what() << '\n';
    usage();
    return 2;
  }
}
