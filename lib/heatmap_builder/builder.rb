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

    def validate_options!
      raise Error, "cell_size must be positive" unless options[:cell_size] > 0
      raise Error, "font_size must be positive" unless options[:font_size] > 0
      raise Error, "colors must be an array" unless options[:colors].is_a?(Array)
      raise Error, "must have at least 2 colors" unless options[:colors].length >= 2
    end

    def default_options
      # Start with base options, then merge subclass-specific options
      DEFAULT_OPTIONS.merge(subclass_default_options)
    end

    def subclass_default_options
      # Override in subclasses to add specific default options
      {}
    end

    def make_color_inactive(hex_color)
      hex = hex_color.delete("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)

      # Blend with light gray to make it appear duller/inactive
      gray = 230
      mix_ratio = 0.6 # 60% original color, 40% gray

      r = blend_color_component(r, gray, mix_ratio)
      g = blend_color_component(g, gray, mix_ratio)
      b = blend_color_component(b, gray, mix_ratio)

      "#%02x%02x%02x" % [r, g, b]
    end

    def blend_color_component(original, target, mix_ratio)
      (original * mix_ratio + target * (1 - mix_ratio)).to_i
    end
  end
end
