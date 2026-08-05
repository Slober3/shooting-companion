#include "opencv_backend.hpp"

#include <stdexcept>

namespace sc::vision {

bool opencv_backend_available() noexcept { return false; }

AnalyzeResult analyze_with_opencv(const AnalyzeRequest&) {
  throw std::logic_error("OpenCV backend is not compiled into this build");
}

}  // namespace sc::vision
