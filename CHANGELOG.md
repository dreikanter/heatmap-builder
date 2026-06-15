# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.2] - 2026-06-15

### Added
- New `border_lightness_factor` option controls how the cell border color is derived
  from each cell's color by scaling its OKLCH lightness. Setting it to `1` makes
  the border match the cell color, in which case the (now invisible) border is
  omitted from the SVG entirely. Defaults to `0.9`, preserving previous output.

## [0.4.1] - 2026-06-13

### Changed
- Default value-to-score conversion now reserves score `0` for empty cells
  (zero or missing values) and maps every non-zero value into the `1..max_score`
  range, so the smallest amount of activity is always visually distinct from an
  empty day. Regenerated `examples/*.svg` to reflect the new bucketing.
- Auto-calculated `value_min` now anchors on the smallest non-zero value instead
  of zero. Because zero is the reserved empty bucket, this keeps the lightest
  activity color reachable rather than stranding it on values that never occur.

### Fixed
- Example calendar heatmaps misrendered high-activity days. The generator passed
  raw values straight through as `scores:`, so any value beyond the palette's
  color count wrapped around via modulo (`score_to_color`) and the busiest days
  could render as nearly empty cells. The examples now feed values through the
  bucketing conversion, so cell intensity increases monotonically with the
  underlying value.

## [0.4.0] - 2026-06-12

### Added
- Tooltip support for calendar cells via the `tooltip:` option. Accepts a callable
  invoked per active cell with `date:`, `score:`, and `value:` keyword arguments;
  the return value becomes the tooltip text.
- Native SVG `<title>` element is always emitted as a zero-JS browser fallback.
- `tooltip_attribute:` option (default `"data-tooltip"`) controls which `data-*`
  attribute is written on the cell's `<g>` wrapper for JS tooltip library pickup.
  Set to `nil` to suppress the data attribute and use only the native fallback.

## [0.3.1] - 2026-06-11

### Changed
- Relaxed `rake` and `minitest` development dependency constraints from `~>` to `>=` to allow future major versions

## [0.3.0] - 2026-06-11

### Changed
- Dropped support for Ruby 3.0, 3.1, and 3.2 (all EOL); minimum required version is now 3.3
- Updated all dependencies to latest stable versions
- Updated Bundler constraint from `~> 2.0` to `>= 2.0`; locked to Bundler 4.0.14
- CI matrix updated to Ruby 3.3, 3.4, and 4.0

## [0.2.0] - 2025-10-02

### Added
- Support for raw numeric values with automatic score calculation using linear distribution
- `values:` parameter as alternative to `scores:` for both linear and calendar heatmaps
- `value_min:` and `value_max:` options for explicit boundary control
- `value_to_score:` option for custom value-to-score conversion functions
- Automatic boundary detection from input data when not explicitly specified
- Dynamic color palette generation using OKLCH color space interpolation
- Rounded corners support for heatmap cells via `corner_radius` option
- Test coverage reporting with SimpleCov
- Snapshot testing for visual regression testing
- YARD documentation for public API methods
- Logarithmic scale example for custom scoring logic
- Detailed options documentation in README

### Changed
- Primary API now uses keyword arguments (`scores:`, `values:`, etc.) for clarity and flexibility
- Refactored common validation logic into base Builder class
- Improved test suite with Minitest specs syntax
- Enhanced README with better organization and forward references
- Renamed `num_scores` parameter to `max_score` for better clarity in custom scoring functions
- Automatic corner radius clamping to valid range

### Deprecated
- `HeatmapBuilder.generate_calendar(scores, options)` - use `HeatmapBuilder.build_calendar(scores: scores, **options)` instead
- Old API still works with deprecation warnings for backward compatibility

## [0.1.0] - 2025-09-19

Initial release with core heatmap visualization capabilities.

### Added
- Calendar heatmap generation with `HeatmapBuilder.generate_calendar()`
- GitHub-style color schemes and styling
- Customizable cell size, spacing, colors, and fonts
- Support for custom start of week (Monday/Sunday)
- SVG output format for perfect scaling

[Unreleased]: https://github.com/dreikanter/heatmap-builder/compare/v0.4.1...HEAD
[0.4.1]: https://github.com/dreikanter/heatmap-builder/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/dreikanter/heatmap-builder/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/dreikanter/heatmap-builder/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/dreikanter/heatmap-builder/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/dreikanter/heatmap-builder/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/dreikanter/heatmap-builder/releases/tag/v0.1.0
