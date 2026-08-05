#include "vision_core/vision_core.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <utility>

namespace sc::vision {
namespace {

constexpr double kEpsilon = 1e-12;

double determinant(const std::vector<double>& matrix) {
  return matrix[0] * (matrix[4] * matrix[8] - matrix[5] * matrix[7]) -
         matrix[1] * (matrix[3] * matrix[8] - matrix[5] * matrix[6]) +
         matrix[2] * (matrix[3] * matrix[7] - matrix[4] * matrix[6]);
}

std::vector<double> solve(std::vector<std::vector<double>> coefficients,
                          std::vector<double> values) {
  const auto size = values.size();
  for (std::size_t row = 0; row < size; ++row) {
    coefficients[row].push_back(values[row]);
  }
  for (std::size_t column = 0; column < size; ++column) {
    auto pivot = column;
    for (auto row = column + 1; row < size; ++row) {
      if (std::abs(coefficients[row][column]) >
          std::abs(coefficients[pivot][column])) {
        pivot = row;
      }
    }
    if (std::abs(coefficients[pivot][column]) < kEpsilon) {
      throw std::invalid_argument("Point pairs do not define a homography");
    }
    if (pivot != column) {
      std::swap(coefficients[pivot], coefficients[column]);
    }
    const auto divisor = coefficients[column][column];
    for (auto item = column; item <= size; ++item) {
      coefficients[column][item] /= divisor;
    }
    for (std::size_t row = 0; row < size; ++row) {
      if (row == column) continue;
      const auto factor = coefficients[row][column];
      if (std::abs(factor) < kEpsilon) continue;
      for (auto item = column; item <= size; ++item) {
        coefficients[row][item] -= factor * coefficients[column][item];
      }
    }
  }
  std::vector<double> result(size);
  for (std::size_t index = 0; index < size; ++index) {
    result[index] = coefficients[index][size];
  }
  return result;
}

}  // namespace

Homography::Homography(std::vector<double> row_major_matrix)
    : matrix_(std::move(row_major_matrix)) {
  if (matrix_.size() != 9 ||
      std::any_of(matrix_.begin(), matrix_.end(),
                  [](double value) { return !std::isfinite(value); }) ||
      std::abs(determinant(matrix_)) < kEpsilon) {
    throw std::invalid_argument("A finite, non-singular 3x3 matrix is required");
  }
}

Homography Homography::from_point_pairs(
    const std::vector<Point>& source, const std::vector<Point>& destination) {
  if (source.size() != 4 || destination.size() != 4) {
    throw std::invalid_argument("Exactly four source and destination points are required");
  }
  std::vector<std::vector<double>> coefficients(
      8, std::vector<double>(8, 0.0));
  std::vector<double> values(8, 0.0);
  for (std::size_t index = 0; index < 4; ++index) {
    const auto x = source[index].x;
    const auto y = source[index].y;
    const auto u = destination[index].x;
    const auto v = destination[index].y;
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(u) ||
        !std::isfinite(v)) {
      throw std::invalid_argument("Point coordinates must be finite");
    }
    const auto first = index * 2;
    const auto second = first + 1;
    coefficients[first][0] = x;
    coefficients[first][1] = y;
    coefficients[first][2] = 1.0;
    coefficients[first][6] = -x * u;
    coefficients[first][7] = -y * u;
    values[first] = u;
    coefficients[second][3] = x;
    coefficients[second][4] = y;
    coefficients[second][5] = 1.0;
    coefficients[second][6] = -x * v;
    coefficients[second][7] = -y * v;
    values[second] = v;
  }
  auto solved = solve(std::move(coefficients), std::move(values));
  solved.push_back(1.0);
  return Homography(std::move(solved));
}

Point Homography::apply(Point point) const {
  const auto denominator =
      matrix_[6] * point.x + matrix_[7] * point.y + matrix_[8];
  if (std::abs(denominator) < kEpsilon) {
    throw std::domain_error("Point maps to infinity");
  }
  return {(matrix_[0] * point.x + matrix_[1] * point.y + matrix_[2]) /
              denominator,
          (matrix_[3] * point.x + matrix_[4] * point.y + matrix_[5]) /
              denominator};
}

const std::vector<double>& Homography::matrix() const noexcept {
  return matrix_;
}

bool GrayImage::valid() const noexcept {
  return width > 0 && height > 0 &&
         pixels.size() == static_cast<std::size_t>(width * height);
}

}  // namespace sc::vision
