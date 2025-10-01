module HeatmapBuilder
  module ValueConversion
    private

    def value_min
      @value_min ||= options[:value_min] || calculated_min_from_values
    end

    def value_max
      @value_max ||= options[:value_max] || calculated_max_from_values
    end

    def calculated_min_from_values
      raise NotImplementedError, "Subclasses must implement #calculated_min_from_values"
    end

    def calculated_max_from_values
      raise NotImplementedError, "Subclasses must implement #calculated_max_from_values"
    end

    def color_count
      @color_count ||= begin
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

    def convert_value_to_score(value, **params)
      value = value_min if value.nil?

      if options[:value_to_score]
        score = options[:value_to_score].call(
          value: value,
          min: value_min,
          max: value_max,
          num_scores: color_count,
          **params
        )

        unless score.is_a?(Integer) && score >= 0 && score < color_count
          raise Error, "value_to_score must return an integer between 0 and #{color_count - 1}, got #{score.inspect}"
        end

        return score
      end

      clamped_value = value.clamp(value_min, value_max)

      if value_min == value_max
        0
      else
        range = value_max - value_min
        normalized = (clamped_value - value_min).to_f / range
        (normalized * (color_count - 1)).floor
      end
    end
  end
end
