require_relative "svg_helpers"

module HeatmapBuilder
  class LinearHeatmapBuilder
    include SvgHelpers

    DEFAULT_OPTIONS = {
      cell_size: 10,
      cell_spacing: 1,
      font_size: 8,
      border_width: 1,
      colors: %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39]
    }.freeze

    def initialize(scores, options = {})
      @scores = scores
      @options = DEFAULT_OPTIONS.merge(options)
      validate_options!
    end

    def build
      svg_content = scores.map.with_index do |score, index|
        cell_svg(score, index)
      end.join

      svg_container(
        width: scores.length * options[:cell_size] + (scores.length - 1) * options[:cell_spacing],
        height: options[:cell_size]
      ) { svg_content }
    end

    private

    attr_reader :scores, :options

    def validate_options!
      raise Error, "scores must be an array" unless scores.is_a?(Array)
      raise Error, "cell_size must be positive" unless options[:cell_size] > 0
      raise Error, "font_size must be positive" unless options[:font_size] > 0
      raise Error, "colors must be an array" unless options[:colors].is_a?(Array)
      raise Error, "must have at least 2 colors" unless options[:colors].length >= 2
    end


    def cell_svg(score, index)
      # Calculate x position - each cell takes cell_size + spacing
      x = index * (options[:cell_size] + options[:cell_spacing])
      y = 0

      color = score_to_color(score, colors: options[:colors])

      # Create colored square (full cell size)
      colored_rect = svg_rect(
        x: x, y: y,
        width: options[:cell_size], height: options[:cell_size],
        fill: color
      )

      border_rect = cell_border(
        x, y, color,
        cell_size: options[:cell_size],
        border_width: options[:border_width],
        darker_color_method: method(:darker_color)
      )

      # Calculate text position (center of cell)
      text_x = x + options[:cell_size] / 2
      # For better vertical centering: cell center + font_size * 0.35 (accounts for baseline)
      text_y = y + options[:cell_size] / 2 + options[:font_size] * 0.35

      text_element = svg_text(
        score,
        x: text_x, y: text_y,
        font_size: options[:font_size], fill: text_color(color)
      )

      "#{colored_rect}#{border_rect}#{text_element}"
    end

  end
end
