# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for raw numeric values with automatic score calculation using linear distribution
- `values:` parameter as alternative to `scores:` for both linear and calendar heatmaps
- `value_min:` and `value_max:` options for explicit boundary control
- `value_to_score:` option for custom value-to-score conversion functions
- Automatic boundary detection from input data when not explicitly specified
- Dynamic color palette generation using OKLCH color space interpolation
- Rounded corners support for heatmap cells via `corner_radius` option
- Test coverage reporting with SimpleCov
- Snapshot testing for comprehensive test coverage

### Changed
- Primary API now uses keyword arguments (`scores:`, `values:`, etc.) for clarity and flexibility
- Refactored common validation logic into base Builder class
- Improved test suite with Minitest specs syntax
- Enhanced README with configuration reference and examples

### Deprecated
- `HeatmapBuilder.generate(scores, options)` - use `HeatmapBuilder.build_linear(scores: scores, **options)` instead
- `HeatmapBuilder.generate_calendar(scores, options)` - use `HeatmapBuilder.build_calendar(scores: scores, **options)` instead
- Old API still works with deprecation warnings for backward compatibility

## [0.1.0] - 2025-09-19

Initial release with core heatmap visualization capabilities.

### Added
- Linear heatmap generation with `HeatmapBuilder.generate()`
- Calendar heatmap generation with `HeatmapBuilder.generate_calendar()`
- GitHub-style color schemes and styling
- Customizable cell size, spacing, colors, and fonts
- Support for custom start of week (Monday/Sunday)
- SVG output format for perfect scaling

[Unreleased]: https://github.com/dreikanter/heatmap-builder/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dreikanter/heatmap-builder/releases/tag/v0.1.0
