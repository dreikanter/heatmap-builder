require_relative "heatmap_builder/version"
require_relative "heatmap_builder/svg_helpers"
require_relative "heatmap_builder/color_helpers"
require_relative "heatmap_builder/builder"
require_relative "heatmap_builder/linear_heatmap_builder"
require_relative "heatmap_builder/calendar_heatmap_builder"

module HeatmapBuilder
  class Error < StandardError; end

  # Predefined color palettes for easy access
  GITHUB_GREEN = Builder::GITHUB_GREEN
  BLUE_OCEAN = Builder::BLUE_OCEAN
  WARM_SUNSET = Builder::WARM_SUNSET
  PURPLE_VIBES = Builder::PURPLE_VIBES
  RED_TO_GREEN = Builder::RED_TO_GREEN

  def self.build_linear(scores: nil, values: nil, **options)
    LinearHeatmapBuilder.new(scores: scores, values: values, **options).build
  end

  def self.build_calendar(scores: nil, values: nil, **options)
    CalendarHeatmapBuilder.new(scores: scores, values: values, **options).build
  end

  # Backward compatibility methods for v0.1.0 API
  def self.generate(scores, options = {})
    warn "[DEPRECATION] `HeatmapBuilder.generate(scores, options)` is deprecated and will be removed in v1.0.0. " \
         "Use `HeatmapBuilder.build_linear(scores: scores, **options)` instead."
    build_linear(scores: scores, **options)
  end

  def self.generate_calendar(scores, options = {})
    warn "[DEPRECATION] `HeatmapBuilder.generate_calendar(scores_by_date, options)` is deprecated and will be removed in v1.0.0. " \
         "Use `HeatmapBuilder.build_calendar(scores: scores_by_date, **options)` instead."
    build_calendar(scores: scores, **options)
  end
end
