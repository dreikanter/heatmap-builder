#!/usr/bin/env ruby

require "date"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "heatmap-builder"

def generate_sample_svgs
  # Create examples directory for SVG files
  Dir.mkdir("examples") unless Dir.exist?("examples")

  generated_files = []

  # Basic weekly progress
  puts "Generating basic weekly progress..."
  weekly_scores = [0, 1, 3, 2, 4, 1, 0]
  svg = HeatmapBuilder.generate(weekly_scores, cell_size: 18)
  filepath = "examples/weekly_progress.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Large cells example
  puts "Generating large cells example..."
  large_cell_scores = [1, 2, 3, 4, 5, 6, 7]
  svg = HeatmapBuilder.generate(large_cell_scores, {
    cell_size: 35,
    cell_spacing: 1,
    font_size: 20
  })
  filepath = "examples/large_cells.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Linear heatmap with different palettes
  puts "Generating linear heatmaps with different palettes..."
  linear_scores = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  # GitHub Green palette (default)
  svg = HeatmapBuilder.build_linear(linear_scores, {
    colors: HeatmapBuilder::GITHUB_GREEN,
    cell_size: 18
  })
  filepath = "examples/linear_github_green.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Blue Ocean palette
  svg = HeatmapBuilder.build_linear(linear_scores, {
    colors: HeatmapBuilder::BLUE_OCEAN,
    cell_size: 18
  })
  filepath = "examples/linear_blue_ocean.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Warm Sunset palette
  svg = HeatmapBuilder.build_linear(linear_scores, {
    colors: HeatmapBuilder::WARM_SUNSET,
    cell_size: 18
  })
  filepath = "examples/linear_warm_sunset.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Purple Vibes palette
  svg = HeatmapBuilder.build_linear(linear_scores, {
    colors: HeatmapBuilder::PURPLE_VIBES,
    cell_size: 18
  })
  filepath = "examples/linear_purple_vibes.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Red to Green palette
  svg = HeatmapBuilder.build_linear(linear_scores, {
    colors: HeatmapBuilder::RED_TO_GREEN,
    cell_size: 18
  })
  filepath = "examples/linear_red_to_green.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # GitHub-style calendar
  puts "Generating GitHub-style calendar..."
  calendar_data = sample_calendar_data
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    cell_size: 14,
    month_spacing: 0
  })
  filepath = "examples/calendar_github_style.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Default colors calendar example
  puts "Generating default colors calendar..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    cell_size: 14,
    month_spacing: 0
  })
  filepath = "examples/calendar_default.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Calendar with Blue Ocean palette
  puts "Generating calendar with Blue Ocean palette..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    colors: HeatmapBuilder::BLUE_OCEAN,
    cell_size: 14,
    month_spacing: 0
  })
  filepath = "examples/calendar_blue_ocean.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Calendar with Warm Sunset palette
  puts "Generating calendar with Warm Sunset palette..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    colors: HeatmapBuilder::WARM_SUNSET,
    cell_size: 14,
    month_spacing: 0
  })
  filepath = "examples/calendar_warm_sunset.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Calendar with Purple Vibes palette
  puts "Generating calendar with Purple Vibes palette..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    colors: HeatmapBuilder::PURPLE_VIBES,
    cell_size: 14,
    month_spacing: 0
  })
  filepath = "examples/calendar_purple_vibes.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Calendar with Red to Green palette
  puts "Generating calendar with Red to Green palette..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    colors: HeatmapBuilder::RED_TO_GREEN,
    cell_size: 14,
    month_spacing: 0
  })
  filepath = "examples/calendar_red_to_green.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Calendar with Sunday start
  puts "Generating calendar with Sunday start..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    cell_size: 14,
    start_of_week: :sunday,
    month_spacing: 0
  })
  filepath = "examples/calendar_sunday_start.svg"
  File.write(filepath, svg)
  generated_files << filepath

  # Calendar with outside cells
  puts "Generating calendar with outside cells..."
  svg = HeatmapBuilder.build_calendar(calendar_data, {
    cell_size: 14,
    show_outside_cells: true,
    month_spacing: 0
  })
  filepath = "examples/calendar_with_outside_cells.svg"
  File.write(filepath, svg)
  generated_files << filepath

  puts "\n✅ Sample SVG files generated successfully!"
  puts "📁 Generated files:"
  generated_files.each do |file|
    puts "   - #{file}"
  end
  puts "📂 Total files: #{generated_files.length}"
end

def sample_calendar_data
  # Generate sample data for a full year
  end_date = Date.today
  start_date = Date.new(end_date.year, 1, 1)

  data = {}
  current_date = start_date

  while current_date <= end_date
    # Create some realistic activity patterns with seasonal variation
    base_activity = case current_date.month
    when 1, 2, 12 # Winter - lower activity
      [0, 0, 0, 1, 1, 2]
    when 3, 4, 5 # Spring - increasing activity
      [0, 1, 1, 2, 2, 3, 3]
    when 6, 7, 8 # Summer - peak activity
      [1, 2, 2, 3, 3, 4, 4, 5]
    when 9, 10, 11 # Fall - moderate activity
      [0, 1, 2, 2, 3, 3]
    end

    # Weekend vs weekday patterns
    score = case current_date.wday
    when 0, 6 # Weekend - reduced activity
      ([0, 0] + base_activity.take(3)).sample
    else # Weekday - normal patterns
      base_activity.sample
    end

    data[current_date.to_s] = score

    current_date += 1
  end

  data
end

# Run the generator
if __FILE__ == $0
  generate_sample_svgs
end
