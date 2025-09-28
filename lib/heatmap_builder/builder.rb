require_relative "svg_helpers"
require_relative "color_helpers"

module HeatmapBuilder
  class Builder
    include SvgHelpers
    include ColorHelpers

    # Predefined color palettes
    GITHUB_GREEN = %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39].freeze
    BLUE_OCEAN = %w[#f0f9ff #bae6fd #7dd3fc #38bdf8 #0ea5e9].freeze
    WARM_SUNSET = %w[#fef3e2 #fed7aa #fdba74 #fb923c #f97316].freeze
    PURPLE_VIBES = %w[#f3e8ff #d8b4fe #c084fc #a855f7 #9333ea].freeze

    DEFAULT_OPTIONS = {
      cell_size: 10,
      cell_spacing: 1,
      font_size: 8,
      border_width: 1,
      colors: GITHUB_GREEN,
      text_color: "#000000"
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
      validate_colors_option!
    end

    def validate_colors_option!
      colors = options[:colors]

      if colors.is_a?(Array)
        raise Error, "must have at least 2 colors" unless colors.length >= 2
      elsif colors.is_a?(Hash)
        raise Error, "colors hash must have from, to, and steps keys" unless colors.key?(:from) && colors.key?(:to) && colors.key?(:steps)
        raise Error, "steps must be a number" unless colors[:steps].is_a?(Integer)
        raise Error, "steps must be at least 2" unless colors[:steps] >= 2
      else
        raise Error, "colors must be an array or hash with from/to/steps"
      end
    end

    # Override in subclasses to provide specific default options
    def default_options
      DEFAULT_OPTIONS
    end
  end
end
