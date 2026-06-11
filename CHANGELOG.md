# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/dreikanter/heatmap-builder/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/dreikanter/heatmap-builder/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/dreikanter/heatmap-builder/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/dreikanter/heatmap-builder/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/dreikanter/heatmap-builder/releases/tag/v0.1.0
