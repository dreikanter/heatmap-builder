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

  # Backward compatibility aliases
  class << self
    alias_method :build, :build_linear
    alias_method :generate, :build_linear
    alias_method :generate_calendar, :build_calendar
  end
end
