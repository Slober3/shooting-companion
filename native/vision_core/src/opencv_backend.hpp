#pragma once

#include "vision_core/vision_core.hpp"

namespace sc::vision {

[[nodiscard]] bool opencv_backend_available() noexcept;
[[nodiscard]] AnalyzeResult analyze_with_opencv(const AnalyzeRequest& request);

}  // namespace sc::vision
