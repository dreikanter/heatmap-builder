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

      cell_size_with_spacing = options[:cell_size] + options[:cell_spacing]
      width = dow_label_offset + total_column_count * cell_size_with_spacing + total_month_spacing
      height = month_label_offset + 7 * cell_size_with_spacing

      svg_container(width: width, height: height) { svg_content.join }
    end

    private

    def start_date
      @start_date ||= parsed_date_range.first
    end

    def end_date
      @end_date ||= parsed_date_range.last
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

    def parsed_date_range
      @parsed_date_range ||= begin
        data_keys = (scores || values || {}).keys
        dates = data_keys.map { |d| d.is_a?(Date) ? d : Date.parse(d.to_s) }
        return [Date.today - 365, Date.today] if dates.empty?

        [dates.min, dates.max]
      end
    end

    def calendar_cells_svg
      svg = ""
      current_date = calendar_start_date
      column_index = 0
      last_month = nil
      current_x_offset = 0
      calendar_end_date = calendar_end_date_with_full_weeks
      split_enabled = options[:month_spacing] > 0

      while current_date <= calendar_end_date
        week_start = current_date
        week_end = current_date + 6
        spans_boundary = split_enabled && week_start.month != week_end.month

        if spans_boundary
          # Find the day_index where the month changes
          split_at = (0..6).find { |i| (week_start + i).month != week_start.month }
          new_month_date = week_start + split_at

          # Column A: old month days (day_index 0..split_at-1)
          split_at.times do |day_index|
            svg << render_cell(current_date, column_index, day_index, current_x_offset)
            current_date += 1
          end
          column_index += 1

          # Add month spacing between the two partial columns
          if last_month && month_overlaps_timeframe?(new_month_date)
            current_x_offset += options[:month_spacing]
          end
          last_month = new_month_date.month

          # Column B: new month days (day_index split_at..6)
          (split_at..6).each do |day_index|
            svg << render_cell(current_date, column_index, day_index, current_x_offset)
            current_date += 1
          end
          column_index += 1
        else
          # No split: check for month spacing based on end-of-week month
          end_of_week_month = week_end.month
          if end_of_week_month != last_month && !last_month.nil? && month_overlaps_timeframe?(week_end)
            current_x_offset += options[:month_spacing]
          end
          last_month = end_of_week_month

          # Render all 7 days in a single column
          7.times do |day_index|
            svg << render_cell(current_date, column_index, day_index, current_x_offset)
            current_date += 1
          end
          column_index += 1
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
      labeled_months = {}
      column_index = 0
      x_offset = 0
      last_spacing_month = nil
      current_date = calendar_start_date
      split_enabled = options[:month_spacing] > 0

      while current_date <= calendar_end_date_with_full_weeks
        week_start = current_date
        week_end = current_date + 6

        if split_enabled && week_start.month != week_end.month
          split_at = (0..6).find { |i| (week_start + i).month != week_start.month }
          new_month_date = week_start + split_at

          # Column A: old month
          month_key_a = [week_start.year, week_start.month]
          if !labeled_months.key?(month_key_a) && month_overlaps_timeframe?(week_start)
            svg << month_label_at(column_index, x_offset, week_start)
            labeled_months[month_key_a] = true
          end
          column_index += 1

          # Spacing between columns A and B
          if last_spacing_month && month_overlaps_timeframe?(new_month_date)
            x_offset += options[:month_spacing]
          end
          last_spacing_month = new_month_date.month

          # Column B: new month
          month_key_b = [new_month_date.year, new_month_date.month]
          if !labeled_months.key?(month_key_b) && month_overlaps_timeframe?(new_month_date)
            svg << month_label_at(column_index, x_offset, new_month_date)
            labeled_months[month_key_b] = true
          end
          column_index += 1
        else
          end_of_week_month = week_end.month
          if end_of_week_month != last_spacing_month && !last_spacing_month.nil? && month_overlaps_timeframe?(week_end)
            x_offset += options[:month_spacing]
          end
          last_spacing_month = end_of_week_month

          month_key = [week_end.year, week_end.month]
          if !labeled_months.key?(month_key) && month_overlaps_timeframe?(week_end)
            svg << month_label_at(column_index, x_offset, week_end)
            labeled_months[month_key] = true
          end
          column_index += 1
        end

        current_date += 7
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
      x = dow_label_offset + column_index * cell_size_with_spacing + x_offset + options[:cell_size] * 0.1
      month_name = options[:month_labels][month_date.month - 1]

      svg_text(
        month_name,
        x: x,
        y: calculate_month_label_y,
        text_anchor: "start", font_family: "Arial, sans-serif", font_size: options[:font_size], fill: "#666666"
      )
    end

    def calculate_month_label_y
      options[:font_size] * 1.25
    end

    def total_column_count
      count = 0
      current_date = calendar_start_date
      split_enabled = options[:month_spacing] > 0

      while current_date <= calendar_end_date_with_full_weeks
        week_start = current_date
        week_end = current_date + 6

        if split_enabled && week_start.month != week_end.month
          count += 2
        else
          count += 1
        end

        current_date += 7
      end

      count
    end

    def total_month_spacing
      x_offset = 0
      last_month = nil
      current_date = calendar_start_date
      split_enabled = options[:month_spacing] > 0

      while current_date <= calendar_end_date_with_full_weeks
        week_start = current_date
        week_end = current_date + 6

        if split_enabled && week_start.month != week_end.month
          split_at = (0..6).find { |i| (week_start + i).month != week_start.month }
          new_month_date = week_start + split_at

          if last_month && month_overlaps_timeframe?(new_month_date)
            x_offset += options[:month_spacing]
          end
          last_month = new_month_date.month
        else
          end_of_week_month = week_end.month
          if end_of_week_month != last_month && !last_month.nil? && month_overlaps_timeframe?(week_end)
            x_offset += options[:month_spacing]
          end
          last_month = end_of_week_month
        end

        current_date += 7
      end

      x_offset
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
      options[:show_month_labels] ? options[:font_size] * 1.625 : 0
    end

    def default_options
      DEFAULT_OPTIONS.merge({
        cell_size: 12,
        start_of_week: :monday,
        month_spacing: 0, # extra horizontal space between months
        show_month_labels: true,
        show_day_labels: true,
        show_outside_cells: false, # show cells outside the timeframe with inactive styling
        day_labels: %w[S M T W T F S], # day abbreviations starting from Sunday
        month_labels: %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec] # month abbreviations
      })
    end
  end
end
