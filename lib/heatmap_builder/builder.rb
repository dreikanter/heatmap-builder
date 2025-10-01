require_relative "svg_helpers"
require_relative "color_helpers"

module HeatmapBuilder
  class Builder
    include SvgHelpers
    include ColorHelpers

    GITHUB_GREEN = %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39].freeze
    BLUE_OCEAN = %w[#f0f9ff #bae6fd #7dd3fc #38bdf8 #0ea5e9].freeze
    WARM_SUNSET = %w[#fef3e2 #fed7aa #fdba74 #fb923c #f97316].freeze
    PURPLE_VIBES = %w[#f3e8ff #d8b4fe #c084fc #a855f7 #9333ea].freeze
    RED_TO_GREEN = %w[#f5f5f5 #ff9999 #f7ad6a #d2c768 #99dd99].freeze

    DEFAULT_OPTIONS = {
      cell_size: 10,
      cell_spacing: 1,
      font_size: 8,
      border_width: 1,
      corner_radius: 0,
      colors: GITHUB_GREEN,
      text_color: "#000000"
    }.freeze

    def initialize(scores: nil, values: nil, **options)
      @scores = scores
      @values = values
      @options = default_options.merge(options)
      normalize_options!
      validate_options!
    end

    def build
      raise NotImplementedError, "Subclasses must implement #build"
    end

    private

    attr_reader :scores, :values, :options

    def normalize_options!
      max_radius = (options[:cell_size] / 2.0).floor
      @options[:corner_radius] = options[:corner_radius].clamp(0, max_radius)
    end

    # Override in subclasses to add specific validations by calling super first
    def validate_options!
      raise Error, "cell_size must be positive" unless options[:cell_size].positive?
      raise Error, "font_size must be positive" unless options[:font_size].positive?
      validate_colors_option!
      validate_scores_or_values!
      validate_value_boundaries! if values
    end

    def validate_scores_or_values!
      if scores && values
        raise Error, "cannot provide both scores and values"
      end

      unless scores || values
        raise Error, "must provide either scores or values"
      end
    end

    def validate_value_boundaries!
      return unless options[:value_min] && options[:value_max]
      return unless options[:value_min] > options[:value_max]
      raise Error, "value_min must be less than or equal to value_max"
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

    def default_options
      DEFAULT_OPTIONS
    end
  end
end
