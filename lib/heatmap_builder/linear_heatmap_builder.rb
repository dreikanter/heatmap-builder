require_relative "builder"

module HeatmapBuilder
  class LinearHeatmapBuilder < Builder
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

    alias_method :scores, :data

    def validate_options!
      super
      raise Error, "scores must be an array" unless data.is_a?(Array)
    end

    def cell_svg(score, index)
      x = index * (options[:cell_size] + options[:cell_spacing])
      y = 0

      color = score_to_color(score, colors: options[:colors])

      colored_rect = svg_rect(
        x: x, y: y,
        width: options[:cell_size], height: options[:cell_size],
        rx: options[:corner_radius],
        fill: color
      )

      border_rect = cell_border(
        x, y, color,
        cell_size: options[:cell_size],
        border_width: options[:border_width],
        corner_radius: options[:corner_radius],
        darker_color_method: method(:darker_color)
      )

      text_x = x + options[:cell_size] / 2
      text_y = y + options[:cell_size] / 2 + options[:font_size] * 0.35

      text_element = svg_text(
        score,
        x: text_x, y: text_y,
        font_size: options[:font_size], fill: options[:text_color]
      )

      "#{colored_rect}#{border_rect}#{text_element}"
    end
  end
end
