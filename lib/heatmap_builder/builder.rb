require_relative "svg_helpers"

module HeatmapBuilder
  class Builder
    include SvgHelpers

    DEFAULT_OPTIONS = {
      cell_size: 10,
      cell_spacing: 1,
      font_size: 8,
      border_width: 1,
      colors: %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39]
    }.freeze

    def initialize(data, options = {})
      @data = data
      @options = default_options.merge(options)
      validate_options!
    end

    def build
      raise NotImplementedError, "Subclasses must implement #build"
    end

    private

    attr_reader :data, :options

    # Override in subclasses to add specific validations by calling super first
    def validate_options!
      raise Error, "cell_size must be positive" unless options[:cell_size] > 0
      raise Error, "font_size must be positive" unless options[:font_size] > 0
      raise Error, "colors must be an array" unless options[:colors].is_a?(Array)
      raise Error, "must have at least 2 colors" unless options[:colors].length >= 2
    end

    # Override in subclasses to provide specific default options
    def default_options
      DEFAULT_OPTIONS
    end
  end
end
