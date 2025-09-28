require_relative "svg_helpers"

module HeatmapBuilder
  class Builder
    include SvgHelpers

    def initialize(data, options = {})
      @data = data
      @options = self.class::DEFAULT_OPTIONS.merge(options)
      validate_options!
    end

    def build
      raise NotImplementedError, "Subclasses must implement #build"
    end

    private

    attr_reader :data, :options

    def validate_options!
      validate_common_options!
      validate_subclass_options!
    end

    def validate_common_options!
      raise Error, "cell_size must be positive" unless options[:cell_size] > 0
      raise Error, "font_size must be positive" unless options[:font_size] > 0
      raise Error, "colors must be an array" unless options[:colors].is_a?(Array)
      raise Error, "must have at least 2 colors" unless options[:colors].length >= 2
    end

    def validate_subclass_options!
      # Override in subclasses for specific validation
    end

    def make_color_inactive(hex_color)
      hex = hex_color.delete("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)

      # Blend with light gray to make it appear duller/inactive
      gray = 230
      mix_ratio = 0.6 # 60% original color, 40% gray

      r = (r * mix_ratio + gray * (1 - mix_ratio)).to_i
      g = (g * mix_ratio + gray * (1 - mix_ratio)).to_i
      b = (b * mix_ratio + gray * (1 - mix_ratio)).to_i

      "#%02x%02x%02x" % [r, g, b]
    end
  end
end
