require "date"
require_relative "builder"
require_relative "value_conversion"

module HeatmapBuilder
  class CalendarHeatmapBuilder < Builder
    include ValueConversion

    VALID_START_DAYS = %i[sunday monday tuesday wednesday thursday friday saturday].freeze

    WEEK_START_WDAY = {
      sunday: 0,
      monday: 1,
      tuesday: 2,
      wednesday: 3,
      thursday: 4,
      friday: 5,
      saturday: 6
    }.freeze

    def build
      svg_content = []

      if options[:show_day_labels]
        svg_content << day_labels_svg
      end

      svg_content << calendar_cells_svg

      if options[:show_month_labels]
        svg_content << month_labels_svg
      end

      weeks_count = ((calendar_end_date_with_full_weeks - calendar_start_date) / 7).ceil
      month_spacing_total = (months_in_range - 1) * options[:month_spacing]

      cell_size_with_spacing = options[:cell_size] + options[:cell_spacing]
      width = dow_label_offset + weeks_count * cell_size_with_spacing + month_spacing_total
      height = month_label_offset + 7 * cell_size_with_spacing

      svg_container(width: width, height: height) { svg_content.join }
    end

    private

    def start_date
      @start_date ||= parse_date_range.first
    end

    def end_date
      @end_date ||= parse_date_range.last
    end

    def validate_options!
      super

      raise Error, "scores must be a hash" if scores && !scores.is_a?(Hash)
      raise Error, "values must be a hash" if values && !values.is_a?(Hash)

      unless VALID_START_DAYS.include?(options[:start_of_week])
        raise Error, "start_of_week must be one of: #{VALID_START_DAYS.join(", ")}"
      end
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

    def parse_date_range
      data_keys = (scores || values || {}).keys
      dates = data_keys.map { |d| d.is_a?(Date) ? d : Date.parse(d.to_s) }
      return [Date.today - 365, Date.today] if dates.empty?

      [dates.min, dates.max]
    end

    def calendar_cells_svg
      svg = ""
      current_date = calendar_start_date
      week_index = 0
      last_month = nil
      current_x_offset = 0
      calendar_end_date = calendar_end_date_with_full_weeks

      while current_date <= calendar_end_date
        # Check if we need to add month spacing
        if current_date.month != last_month && !last_month.nil?
          current_x_offset += options[:month_spacing]
        end
        last_month = current_date.month

        # Generate week column - always fill all 7 days
        7.times do |day_index|
          x = dow_label_offset + week_index * (options[:cell_size] + options[:cell_spacing]) + current_x_offset
          y = month_label_offset + day_index * (options[:cell_size] + options[:cell_spacing])

          if current_date.between?(start_date, end_date)
            # Active cell within the specified timeframe
            score = scores_by_date[current_date] || scores_by_date[current_date.to_s] || 0
            svg << cell_svg(score, x, y, false)
          elsif options[:show_outside_cells]
            # Inactive cell outside the specified timeframe
            svg << cell_svg(0, x, y, true)
          end

          current_date += 1
        end

        week_index += 1
      end

      svg
    end

    def cell_svg(score, x, y, inactive = false)
      color = score_to_color(score, colors: color_palette)

      if inactive
        color = make_color_inactive(color)
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
        y = month_label_offset + index * (options[:cell_size] + options[:cell_spacing]) + options[:cell_size] / 2 + options[:font_size] * 0.35
        svg << svg_text(
          day_name,
          x: options[:font_size], y: y,
          font_size: options[:font_size], fill: "#666666"
        )
      end

      svg
    end

    def month_labels_svg
      return "" unless options[:show_month_labels]

      svg = ""
      last_month = nil

      each_week do |current_date, _week_index|
        current_month = [current_date.year, current_date.month]

        if current_month != last_month && month_overlaps_timeframe?(current_date)
          svg << render_month_label(current_date)
          last_month = current_month
        end
      end

      svg
    end

    def month_overlaps_timeframe?(current_date)
      month_start = Date.new(current_date.year, current_date.month, 1)
      month_end = Date.new(current_date.year, current_date.month, -1)

      month_start <= end_date && month_end >= start_date
    end

    def render_month_label(current_date)
      first_day_of_month = Date.new(current_date.year, current_date.month, 1)
      month_name = options[:month_labels][current_date.month - 1]

      svg_text(
        month_name,
        x: calculate_month_label_x(first_day_of_month),
        y: calculate_month_label_y,
        text_anchor: "start", font_family: "Arial, sans-serif", font_size: options[:font_size], fill: "#666666"
      )
    end

    def calculate_month_label_y
      options[:font_size] * 1.25
    end

    def calculate_month_label_x(first_day_of_month)
      days_from_start = (first_day_of_month - calendar_start_date).to_i
      week_index = days_from_start / 7
      x_offset = calculate_x_offset_for_week(week_index)

      dow_label_offset + week_index * (options[:cell_size] + options[:cell_spacing]) + x_offset + options[:cell_size] * 0.1
    end

    def calculate_x_offset_for_week(target_week_index)
      x_offset = 0
      last_month = nil

      each_week do |current_date, week_index|
        break if week_index >= target_week_index

        if current_date.month != last_month && !last_month.nil?
          x_offset += options[:month_spacing]
        end

        last_month = current_date.month
      end

      x_offset
    end

    def each_week
      current_date = calendar_start_date
      week_index = 0

      while current_date <= calendar_end_date_with_full_weeks
        yield current_date, week_index

        current_date += 7
        week_index += 1
      end
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

    def month_spacing_weeks
      options[:month_spacing] / (options[:cell_size] + options[:cell_spacing])
    end

    def dow_label_offset
      options[:show_day_labels] ? options[:font_size] * 2 : 0
    end

    def month_label_offset
      options[:show_month_labels] ? options[:font_size] * 1.625 : 0
    end

    def months_in_range
      ((end_date.year - start_date.year) * 12 + end_date.month - start_date.month + 1)
    end

    def default_options
      DEFAULT_OPTIONS.merge({
        cell_size: 12,
        start_of_week: :monday,
        month_spacing: 5, # extra horizontal space between months
        show_month_labels: true,
        show_day_labels: true,
        show_outside_cells: false, # show cells outside the timeframe with inactive styling
        day_labels: %w[S M T W T F S], # day abbreviations starting from Sunday
        month_labels: %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec] # month abbreviations
      })
    end
  end
end
