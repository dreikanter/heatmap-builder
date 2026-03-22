require_relative "heatmap_builder/version"
require_relative "heatmap_builder/svg_helpers"
require_relative "heatmap_builder/color_helpers"
require_relative "heatmap_builder/value_conversion"
require_relative "heatmap_builder/calendar_heatmap_builder"

module HeatmapBuilder
  class Error < StandardError; end

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

  # @deprecated Use {.build_calendar} instead
  def self.generate_calendar(scores, options = {})
    warn "[DEPRECATION] `HeatmapBuilder.generate_calendar(scores_by_date, options)` is deprecated and will be removed in v1.0.0. " \
         "Use `HeatmapBuilder.build_calendar(scores: scores_by_date, **options)` instead."
    build_calendar(scores: scores, **options)
  end
end
