require_relative "builder"

module HeatmapBuilder
  class LinearHeatmapBuilder < Builder
    def build
      svg_content = computed_scores.map.with_index do |score, index|
        cell_svg(score, index)
      end.join

      svg_container(
        width: computed_scores.length * options[:cell_size] + (computed_scores.length - 1) * options[:cell_spacing],
        height: options[:cell_size]
      ) { svg_content }
    end

    private

    def validate_options!
      super

      if scores
        raise Error, "scores must be an array" unless scores.is_a?(Array)
      end

      if values
        raise Error, "values must be an array" unless values.is_a?(Array)
      end
    end

    def computed_scores
      @computed_scores ||= scores || values.map.with_index { |value, index| value_to_score(value, index) }
    end

    # Converts a raw value to a score bucket using linear distribution
    # Nil values are normalized to the minimum boundary
    def value_to_score(value, index)
      value = value_min if value.nil?

      if options[:value_to_score]
        score = options[:value_to_score].call(
          value: value,
          index: index,
          min: value_min,
          max: value_max,
          num_scores: num_scores
        )

        unless score.is_a?(Integer) && score >= 0 && score < num_scores
          raise Error, "value_to_score must return an integer between 0 and #{num_scores - 1}, got #{score.inspect}"
        end

        return score
      end

      clamped_value = value.clamp(value_min, value_max)

      if value_min == value_max
        0
      else
        range = value_max - value_min
        normalized = (clamped_value - value_min).to_f / range
        (normalized * (num_scores - 1)).floor
      end
    end

    def value_min
      @value_min ||= options[:value_min] || calculated_min_from_values
    end

    def value_max
      @value_max ||= options[:value_max] || calculated_max_from_values
    end

    def calculated_min_from_values
      non_nil_values = values.compact
      non_nil_values.empty? ? 0 : non_nil_values.min
    end

    def calculated_max_from_values
      non_nil_values = values.compact
      non_nil_values.empty? ? 0 : non_nil_values.max
    end

    def num_scores
      @num_scores ||= begin
        colors_option = options[:colors]
        if colors_option.is_a?(Array)
          colors_option.length
        elsif colors_option.is_a?(Hash)
          colors_option[:steps]
        else
          raise Error, "colors must be an array or hash"
        end
      end
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
