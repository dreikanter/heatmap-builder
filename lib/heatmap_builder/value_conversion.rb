# frozen_string_literal: true

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
      if options[:value_to_score]
        score = options[:value_to_score].call(
          value: value.nil? ? value_min : value,
          min: value_min,
          max: value_max,
          max_score: color_count - 1,
          **params
        )

        unless score.is_a?(Integer) && score >= 0 && score < color_count
          raise Error, "value_to_score must return an integer between 0 and #{color_count - 1}, got #{score.inspect}"
        end

        return score
      end

      # Score 0 is reserved for empty cells (zero or missing values). Any
      # non-zero value maps into 1..max_score so even the smallest activity is
      # visibly distinct from an empty day.
      return 0 if value.nil? || value.zero?

      max_score = color_count - 1
      clamped_value = value.clamp(value_min, value_max)

      if value_min == value_max
        max_score
      else
        range = value_max - value_min
        normalized = (clamped_value - value_min).to_f / range
        1 + (normalized * (max_score - 1)).round
      end
    end
  end
end
