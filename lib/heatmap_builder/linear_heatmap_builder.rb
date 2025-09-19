module HeatmapBuilder
  class LinearHeatmapBuilder
    DEFAULT_OPTIONS = {
      cell_size: 10,
      cell_spacing: 1,
      font_size: 8,
      cells_per_row: 7,
      border_width: 1,
      colors: %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39]
    }.freeze

    def initialize(scores, options = {})
      @scores = scores
      @options = DEFAULT_OPTIONS.merge(options)
      validate_options!
    end

    def generate
      build_svg
    end

    private

    attr_reader :scores, :options

    def validate_options!
      raise Error, "scores must be an array" unless scores.is_a?(Array)
      raise Error, "cell_size must be positive" unless options[:cell_size] > 0
      raise Error, "font_size must be positive" unless options[:font_size] > 0
      raise Error, "cells_per_row must be positive" unless options[:cells_per_row] > 0
      raise Error, "colors must be an array" unless options[:colors].is_a?(Array)
      raise Error, "must have at least 2 colors" unless options[:colors].length >= 2
    end

    def build_svg
      width = svg_width
      height = svg_height

      svg_content = scores.first(options[:cells_per_row]).map.with_index do |score, index|
        cell_svg(score, index)
      end.join

      <<~SVG
        <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
          #{svg_content}
        </svg>
      SVG
    end

    def cell_svg(score, index)
      # Calculate x position - each cell takes cell_size + spacing
      x = index * (options[:cell_size] + options[:cell_spacing])
      y = 0

      color = score_to_color(score)

      # Create colored square (full cell size)
      colored_rect = "<rect x=\"#{x}\" y=\"#{y}\" width=\"#{options[:cell_size]}\" height=\"#{options[:cell_size]}\" fill=\"#{color}\"/>"

      # Create border overlay completely inside the colored square
      border_rect = if options[:border_width] > 0
        # Inset the border rect by half the stroke width so stroke stays inside
        inset = options[:border_width] / 2.0
        border_x = x + inset
        border_y = y + inset
        border_size = options[:cell_size] - options[:border_width]
        border_color = darker_color(color)
        "<rect x=\"#{border_x}\" y=\"#{border_y}\" width=\"#{border_size}\" height=\"#{border_size}\" fill=\"none\" stroke=\"#{border_color}\" stroke-width=\"#{options[:border_width]}\"/>"
      else
        ""
      end

      # Calculate text position (center of cell)
      text_x = x + options[:cell_size] / 2
      # For better vertical centering: cell center + font_size * 0.35 (accounts for baseline)
      text_y = y + options[:cell_size] / 2 + options[:font_size] * 0.35

      text_element = "<text x=\"#{text_x}\" y=\"#{text_y}\" text-anchor=\"middle\" font-family=\"Arial, sans-serif\" font-size=\"#{options[:font_size]}\" fill=\"#{text_color(color)}\">#{score}</text>"

      "#{colored_rect}#{border_rect}#{text_element}"
    end

    def score_to_color(score)
      return options[:colors].first if score == 0

      max_color_index = options[:colors].length - 1
      # Map score to color index, ensuring we don't exceed available colors
      color_index = 1 + (score - 1) % max_color_index
      options[:colors][color_index]
    end

    def text_color(background_color)
      # Simple contrast check - if dark background, use white text
      hex = background_color.delete("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
      brightness = (r * 299 + g * 587 + b * 114) / 1000
      (brightness > 128) ? "#000000" : "#ffffff"
    end

    def svg_width
      options[:cells_per_row] * options[:cell_size] +
        (options[:cells_per_row] - 1) * options[:cell_spacing]
    end

    def svg_height
      options[:cell_size]
    end

    def darker_color(hex_color)
      # Remove # if present
      hex = hex_color.delete("#")

      # Extract RGB values
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)

      # Make 30% darker
      r = (r * 0.7).to_i
      g = (g * 0.7).to_i
      b = (b * 0.7).to_i

      "#%02x%02x%02x" % [r, g, b]
    end
  end
end
