require "date"
require_relative "svg_helpers"
require_relative "color_helpers"
require_relative "value_conversion"

module HeatmapBuilder
  class Calendar
    include SvgHelpers
    include ValueConversion

    GITHUB_GREEN = %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39].freeze
    BLUE_OCEAN = %w[#f0f9ff #bae6fd #7dd3fc #38bdf8 #0ea5e9].freeze
    WARM_SUNSET = %w[#fef3e2 #fed7aa #fdba74 #fb923c #f97316].freeze
    PURPLE_VIBES = %w[#f3e8ff #d8b4fe #c084fc #a855f7 #9333ea].freeze
    RED_TO_GREEN = %w[#f5f5f5 #ff9999 #f7ad6a #d2c768 #99dd99].freeze

    DEFAULT_OPTIONS = {
      cell_size: 12,
      cell_spacing: 1,
      font_size: 8,
      border_width: 1,
      corner_radius: 0,
      colors: GITHUB_GREEN,
      start_of_week: :monday,
      month_spacing: 0,
      show_month_labels: true,
      show_day_labels: true,
      show_outside_cells: false,
      day_labels: %w[S M T W T F S],
      month_labels: %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    }.freeze

    VALID_START_DAYS = %i[sunday monday tuesday wednesday thursday friday saturday].freeze

    LABEL_COLOR = "#666666"
    FONT_VERTICAL_CENTER_RATIO = 0.35
    MONTH_LABEL_Y_RATIO = 1.25
    MONTH_LABEL_HEIGHT_RATIO = 1.625
    MONTH_LABEL_INDENT_RATIO = 0.1

    WEEK_START_WDAY = {
      sunday: 0,
      monday: 1,
      tuesday: 2,
      wednesday: 3,
      thursday: 4,
      friday: 5,
      saturday: 6
    }.freeze

    def initialize(scores: nil, values: nil, **options)
      @scores = scores
      @values = values
      @options = DEFAULT_OPTIONS.merge(options)
      validate_options!
      normalize_options!
    end

    def build
      svg_content = []

      if options[:show_day_labels]
        svg_content << day_labels_svg
      end

      svg_content << calendar_cells_svg

      if options[:show_month_labels]
        svg_content << month_labels_svg
      end

      cell_size_with_spacing = options[:cell_size] + options[:cell_spacing]
      width = dow_label_offset + total_column_count * cell_size_with_spacing + total_month_spacing
      height = month_label_offset + 7 * cell_size_with_spacing

      svg_container(width: width, height: height) { svg_content.join }
    end

    private

    attr_reader :scores, :values, :options

    def normalize_options!
      max_radius = (options[:cell_size] / 2.0).floor
      @options[:corner_radius] = options[:corner_radius].clamp(0, max_radius)
    end

    def validate_options!
      raise Error, "cell_size must be positive" unless options[:cell_size].positive?
      raise Error, "font_size must be positive" unless options[:font_size].positive?
      validate_colors_option!
      validate_scores_or_values!
      validate_value_boundaries! if values

      raise Error, "scores must be a hash" if scores && !scores.is_a?(Hash)
      raise Error, "values must be a hash" if values && !values.is_a?(Hash)

      unless VALID_START_DAYS.include?(options[:start_of_week])
        raise Error, "start_of_week must be one of: #{VALID_START_DAYS.join(", ")}"
      end
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

    def color_palette
      @color_palette ||= begin
        colors_option = options[:colors]
        if colors_option.is_a?(Hash)
          ColorHelpers.generate_color_palette(colors_option[:from], colors_option[:to], colors_option[:steps])
        else
          colors_option
        end
      end
    end

    def start_date
      @start_date ||= parsed_date_range.first
    end

    def end_date
      @end_date ||= parsed_date_range.last
    end

    def scores_by_date
      @scores_by_date ||= if scores
        scores
      else
        result = {}
        current_date = start_date

        while current_date <= end_date
          value = values[current_date] || values[current_date.to_s]
          result[current_date] = convert_value_to_score(value, date: current_date)
          current_date += 1
        end

        result
      end
    end

    def calculated_min_from_values
      non_nil_values = values.values.compact
      non_nil_values.empty? ? 0 : non_nil_values.min
    end

    def calculated_max_from_values
      non_nil_values = values.values.compact
      non_nil_values.empty? ? 0 : non_nil_values.max
    end

    def parsed_date_range
      @parsed_date_range ||= begin
        data_keys = (scores || values || {}).keys
        dates = data_keys.map { |d| d.is_a?(Date) ? d : Date.parse(d.to_s) }
        return [Date.today - 365, Date.today] if dates.empty?

        [dates.min, dates.max]
      end
    end

    def column_layout
      @column_layout ||= build_column_layout
    end

    def build_column_layout
      columns = []
      current_date = calendar_start_date
      cal_end = calendar_end_date_with_full_weeks
      split_enabled = options[:month_spacing] > 0
      col_idx = 0
      x_offset = 0
      last_month = nil
      labeled_months = {}

      while current_date <= cal_end
        week_start = current_date
        week_end = current_date + 6

        if split_enabled && week_start.month != week_end.month
          split_at = (0..6).find { |i| (week_start + i).month != week_start.month }
          new_month_date = week_start + split_at

          # Column A: old month days (day_index 0..split_at-1)
          days_a = (0...split_at).map { |i| [week_start + i, i] }
          month_key_a = [week_start.year, week_start.month]
          first_a = !labeled_months.key?(month_key_a) && month_overlaps_timeframe?(week_start)
          labeled_months[month_key_a] = true if first_a
          columns << {index: col_idx, x_offset: x_offset, days: days_a, month_date: week_start, first_of_month: first_a}
          col_idx += 1

          # Spacing between columns A and B
          if last_month && month_overlaps_timeframe?(new_month_date)
            x_offset += options[:month_spacing]
          end
          last_month = new_month_date.month

          # Column B: new month days (day_index split_at..6)
          # Don't place month label on split column — defer to first full column
          days_b = (split_at..6).map { |i| [week_start + i, i] }
          columns << {index: col_idx, x_offset: x_offset, days: days_b, month_date: new_month_date, first_of_month: false}
        else
          end_of_week_month = week_end.month
          if end_of_week_month != last_month && !last_month.nil? && month_overlaps_timeframe?(week_end)
            x_offset += options[:month_spacing]
          end
          last_month = end_of_week_month

          days = (0..6).map { |i| [week_start + i, i] }
          month_key = [week_end.year, week_end.month]
          first = !labeled_months.key?(month_key) && month_overlaps_timeframe?(week_end)
          labeled_months[month_key] = true if first
          columns << {index: col_idx, x_offset: x_offset, days: days, month_date: week_end, first_of_month: first}
        end

        col_idx += 1
        current_date += 7
      end

      columns
    end

    def calendar_cells_svg
      svg = ""
      column_layout.each do |col|
        col[:days].each do |date, day_index|
          svg << render_cell(date, col[:index], day_index, col[:x_offset])
        end
      end
      svg
    end

    def render_cell(current_date, column_index, day_index, x_offset)
      x = dow_label_offset + column_index * (options[:cell_size] + options[:cell_spacing]) + x_offset
      y = month_label_offset + day_index * (options[:cell_size] + options[:cell_spacing])

      if current_date.between?(start_date, end_date)
        score = scores_by_date[current_date] || scores_by_date[current_date.to_s] || 0
        cell_svg(score, x, y, false)
      elsif options[:show_outside_cells]
        cell_svg(0, x, y, true)
      else
        ""
      end
    end

    def cell_svg(score, x, y, inactive = false)
      color = ColorHelpers.score_to_color(score, colors: color_palette)

      if inactive
        color = ColorHelpers.make_color_inactive(color)
      end

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
        corner_radius: options[:corner_radius]
      )

      "#{colored_rect}#{border_rect}"
    end

    def day_labels_svg
      return "" unless options[:show_day_labels]

      day_names = day_names_for_week_start
      svg = ""

      day_names.each_with_index do |day_name, index|
        y = month_label_offset + index * (options[:cell_size] + options[:cell_spacing]) + options[:cell_size] / 2 + options[:font_size] * FONT_VERTICAL_CENTER_RATIO
        svg << svg_text(
          day_name,
          x: options[:font_size], y: y,
          font_size: options[:font_size], fill: LABEL_COLOR
        )
      end

      svg
    end

    def month_labels_svg
      return "" unless options[:show_month_labels]

      svg = ""
      column_layout.each do |col|
        if col[:first_of_month]
          svg << month_label_at(col[:index], col[:x_offset], col[:month_date])
        end
      end
      svg
    end

    def month_overlaps_timeframe?(date)
      month_start = Date.new(date.year, date.month, 1)
      month_end = Date.new(date.year, date.month, -1)

      month_start <= end_date && month_end >= start_date
    end

    def month_label_at(column_index, x_offset, month_date)
      cell_size_with_spacing = options[:cell_size] + options[:cell_spacing]
      x = dow_label_offset + column_index * cell_size_with_spacing + x_offset + options[:cell_size] * MONTH_LABEL_INDENT_RATIO
      month_name = options[:month_labels][month_date.month - 1]

      svg_text(
        month_name,
        x: x,
        y: calculate_month_label_y,
        text_anchor: "start", font_family: "Arial, sans-serif", font_size: options[:font_size], fill: LABEL_COLOR
      )
    end

    def calculate_month_label_y
      options[:font_size] * MONTH_LABEL_Y_RATIO
    end

    def total_column_count
      column_layout.length
    end

    def total_month_spacing
      column_layout.last&.dig(:x_offset) || 0
    end

    # Find the start of the week containing start_date
    def calendar_start_date
      days_back = (start_date.wday - week_start_wday) % 7
      start_date - days_back
    end

    # Find the end of the week containing end_date
    def calendar_end_date_with_full_weeks
      days_forward = (6 - (end_date.wday - week_start_wday)) % 7
      end_date + days_forward
    end

    def week_start_wday
      WEEK_START_WDAY[options[:start_of_week]]
    end

    def day_names_for_week_start
      start_index = week_start_wday
      options[:day_labels].rotate(start_index)
    end

    def dow_label_offset
      options[:show_day_labels] ? options[:font_size] * 2 : 0
    end

    def month_label_offset
      options[:show_month_labels] ? options[:font_size] * MONTH_LABEL_HEIGHT_RATIO : 0
    end
  end
end
