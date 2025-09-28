require_relative "heatmap_builder/version"
require_relative "heatmap_builder/svg_helpers"
require_relative "heatmap_builder/linear_heatmap_builder"
require_relative "heatmap_builder/calendar_heatmap_builder"

module HeatmapBuilder
  class Error < StandardError; end

  def self.generate(scores, options = {})
    LinearHeatmapBuilder.new(scores, options).build
  end

  def self.generate_calendar(scores_by_date, options = {})
    CalendarHeatmapBuilder.new(scores_by_date, options).build
  end
end
