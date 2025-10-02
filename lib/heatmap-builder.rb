require_relative "heatmap_builder/version"
require_relative "heatmap_builder/svg_helpers"
require_relative "heatmap_builder/color_helpers"
require_relative "heatmap_builder/value_conversion"
require_relative "heatmap_builder/builder"
require_relative "heatmap_builder/linear_heatmap_builder"
require_relative "heatmap_builder/calendar_heatmap_builder"

module HeatmapBuilder
  class Error < StandardError; end

  GITHUB_GREEN = Builder::GITHUB_GREEN
  BLUE_OCEAN = Builder::BLUE_OCEAN
  WARM_SUNSET = Builder::WARM_SUNSET
  PURPLE_VIBES = Builder::PURPLE_VIBES
  RED_TO_GREEN = Builder::RED_TO_GREEN

  # Builds a linear (single-row) heatmap visualization.
  #
  # @param scores [Array<Integer>, nil] Pre-calculated score values (0 to num_colors-1). Required unless values provided.
  # @param values [Array<Numeric>, nil] Raw numeric values to be mapped to scores. Required unless scores provided.
  # @param options [Hash] Customization options
  # @return [String] SVG markup
  # @see https://github.com/dreikanter/heatmap-builder#linear-heatmaps Full documentation
  # @example
  #   HeatmapBuilder.build_linear(scores: [0, 1, 2, 3, 4])
  #   HeatmapBuilder.build_linear(values: [10, 25, 50, 75, 100], value_min: 0, value_max: 100)
  def self.build_linear(scores: nil, values: nil, **options)
    LinearHeatmapBuilder.new(scores: scores, values: values, **options).build
  end

  # Builds a calendar (GitHub-style) heatmap visualization.
  #
  # @param scores [Hash<Date, Integer>, Hash<String, Integer>, nil] Pre-calculated score values by date. Required unless values provided.
  # @param values [Hash<Date, Numeric>, Hash<String, Numeric>, nil] Raw numeric values by date. Required unless scores provided.
  # @param options [Hash] Customization options
  # @return [String] SVG markup
  # @see https://github.com/dreikanter/heatmap-builder#calendar-heatmaps Full documentation
  # @example
  #   HeatmapBuilder.build_calendar(scores: { '2024-01-01' => 2, '2024-01-02' => 4 })
  #   HeatmapBuilder.build_calendar(values: { Date.new(2024, 1, 1) => 45.2 })
  def self.build_calendar(scores: nil, values: nil, **options)
    CalendarHeatmapBuilder.new(scores: scores, values: values, **options).build
  end

  # @deprecated Use {.build_linear} instead
  def self.generate(scores, options = {})
    warn "[DEPRECATION] `HeatmapBuilder.generate(scores, options)` is deprecated and will be removed in v1.0.0. " \
         "Use `HeatmapBuilder.build_linear(scores: scores, **options)` instead."
    build_linear(scores: scores, **options)
  end

  # @deprecated Use {.build_calendar} instead
  def self.generate_calendar(scores, options = {})
    warn "[DEPRECATION] `HeatmapBuilder.generate_calendar(scores_by_date, options)` is deprecated and will be removed in v1.0.0. " \
         "Use `HeatmapBuilder.build_calendar(scores: scores_by_date, **options)` instead."
    build_calendar(scores: scores, **options)
  end
end
