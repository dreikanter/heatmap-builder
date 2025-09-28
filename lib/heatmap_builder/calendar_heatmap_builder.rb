require "date"
require_relative "builder"

module HeatmapBuilder
  class CalendarHeatmapBuilder < Builder
    DEFAULT_OPTIONS = {
      cell_size: 12,
      cell_spacing: 1,
      font_size: 8,
      border_width: 1,
      colors: %w[#ebedf0 #9be9a8 #40c463 #30a14e #216e39],
      start_of_week: :monday,
      month_spacing: 5, # extra vertical space between months
      show_month_labels: true,
      show_day_labels: true,
      show_outside_cells: false, # show cells outside the timeframe with inactive styling
      day_labels: %w[S M T W T F S], # day abbreviations starting from Sunday
      month_labels: %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec] # month abbreviations
    }.freeze

    def initialize(scores_by_date, options = {})
      super
      @start_date = parse_date_range.first
      @end_date = parse_date_range.last
    end

    def build
      svg_content = []

      # Add day labels if enabled
      if options[:show_day_labels]
        svg_content << day_labels_svg
      end

      # Add month labels and cells
      svg_content << calendar_cells_svg

      if options[:show_month_labels]
        svg_content << month_labels_svg
      end

      weeks_count = ((calendar_end_date_with_full_weeks - calendar_start_date) / 7).ceil
      month_spacing_total = (months_in_range - 1) * options[:month_spacing]
      width = label_offset + weeks_count * (options[:cell_size] + options[:cell_spacing]) + month_spacing_total
      height = day_label_offset + 7 * (options[:cell_size] + options[:cell_spacing])

      svg_container(width: width, height: height) { svg_content.join }
    end

    private

    alias_method :scores_by_date, :data

    attr_reader :start_date, :end_date

    def validate_subclass_options!
      raise Error, "scores_by_date must be a hash" unless data.is_a?(Hash)

      valid_start_days = %i[sunday monday tuesday wednesday thursday friday saturday]
      unless valid_start_days.include?(options[:start_of_week])
        raise Error, "start_of_week must be one of: #{valid_start_days.join(", ")}"
      end
    end

    def parse_date_range
      dates = scores_by_date.keys.map { |d| d.is_a?(Date) ? d : Date.parse(d.to_s) }
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
          x = label_offset + week_index * (options[:cell_size] + options[:cell_spacing]) + current_x_offset
          y = day_label_offset + day_index * (options[:cell_size] + options[:cell_spacing])

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
      color = score_to_color(score, colors: options[:colors])

      # Make inactive cells duller by reducing opacity
      if inactive
        color = make_color_inactive(color)
      end

      # Create colored square
      colored_rect = svg_rect(
        x: x, y: y,
        width: options[:cell_size], height: options[:cell_size],
        fill: color
      )

      border_rect = cell_border(
        x, y, color,
        cell_size: options[:cell_size],
        border_width: options[:border_width],
        darker_color_method: ->(c) { darker_color(c, factor: 0.9) }
      )

      "#{colored_rect}#{border_rect}"
    end

    def day_labels_svg
      return "" unless options[:show_day_labels]

      day_names = day_names_for_week_start
      svg = ""

      day_names.each_with_index do |day_name, index|
        y = day_label_offset + index * (options[:cell_size] + options[:cell_spacing]) + options[:cell_size] / 2 + options[:font_size] * 0.35
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
      current_date = calendar_start_date
      week_index = 0
      last_month = nil
      displayed_months = {}
      current_x_offset = 0
      calendar_end_date = calendar_end_date_with_full_weeks

      while current_date <= calendar_end_date
        # Check if we need to add month spacing
        if current_date.month != last_month && !last_month.nil?
          current_x_offset += options[:month_spacing]
        end

        # Add month label at start of each month, but only if the month overlaps with our specified timeframe
        if current_date.month != last_month && !displayed_months[current_date.month]
          # Check if this month has any days within our specified timeframe
          month_start = Date.new(current_date.year, current_date.month, 1)
          month_end = Date.new(current_date.year, current_date.month, -1)

          if month_start <= end_date && month_end >= start_date
            x = label_offset + week_index * (options[:cell_size] + options[:cell_spacing]) + current_x_offset
            y = options[:font_size] + 2
            month_name = options[:month_labels][current_date.month - 1]
            svg << svg_text(
              month_name,
              x: x, y: y,
              font_family: "Arial, sans-serif", font_size: options[:font_size], fill: "#666666"
            )
          end

          displayed_months[current_date.month] = true
        end

        last_month = current_date.month
        current_date += 7
        week_index += 1
      end

      svg
    end

    def calendar_start_date
      # Find the start of the week containing start_date
      days_back = (start_date.wday - week_start_wday) % 7
      start_date - days_back
    end

    def calendar_end_date_with_full_weeks
      # Find the end of the week containing end_date
      days_forward = (6 - (end_date.wday - week_start_wday)) % 7
      end_date + days_forward
    end

    def week_start_wday
      case options[:start_of_week]
      when :sunday then 0
      when :monday then 1
      when :tuesday then 2
      when :wednesday then 3
      when :thursday then 4
      when :friday then 5
      when :saturday then 6
      end
    end

    def day_names_for_week_start
      start_index = week_start_wday
      options[:day_labels].rotate(start_index)
    end

    def month_spacing_weeks
      options[:month_spacing] / (options[:cell_size] + options[:cell_spacing])
    end

    def label_offset
      options[:show_day_labels] ? options[:font_size] * 2 : 0
    end

    def day_label_offset
      options[:show_month_labels] ? options[:font_size] + 5 : 0
    end

    def months_in_range
      ((end_date.year - start_date.year) * 12 + end_date.month - start_date.month + 1)
    end
  end
end
