require "test_helper"

describe HeatmapBuilder::CalendarHeatmapBuilder do
  def scores
    {
      "2024-01-01" => 1,
      "2024-01-02" => 2,
      "2024-01-03" => 0,
      "2024-01-07" => 3
    }
  end

  def builder
    HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores)
  end

  it "should build SVG with default options" do
    svg = builder.build
    assert_matches_snapshot(svg, "calendar_basic.svg")
  end

  it "should use Monday as start of week when specified" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, start_of_week: :monday)
    assert_matches_snapshot(builder.build, "start_with_monday.svg")
  end

  it "should use Sunday as start of week when specified" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, start_of_week: :sunday)
    assert_matches_snapshot(builder.build, "start_with_sunday.svg")
  end

  it "should display month labels when enabled" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, show_month_labels: true)
    assert_matches_snapshot(builder.build, "with_months.svg")
  end

  it "should display day labels when enabled" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, show_day_labels: true)
    assert_matches_snapshot(builder.build, "with_dows.svg")
  end

  it "should use custom colors when provided" do
    colors = %w[#ffffff #ff0000 #00ff00]
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, colors: colors)
    assert_matches_snapshot(builder.build, "custom_colors.svg")
  end

  it "should raise errors for invalid inputs" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(scores: "invalid")
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, cell_size: 0)
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, colors: [])
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, start_of_week: :invalid)
    end
  end

  it "should accept Date objects as keys" do
    date_scores = {
      Date.new(2024, 1, 1) => 1,
      Date.new(2024, 1, 2) => 2
    }

    assert HeatmapBuilder::CalendarHeatmapBuilder.new(scores: date_scores)
  end

  it "should handle empty scores hash" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: {})
    assert builder.build
  end

  it "should apply corner_radius to cells" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, corner_radius: 2)
    svg = builder.build

    assert_includes svg, 'rx="2"'
  end

  it "should normalize corner_radius to maximum allowed value" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(scores: scores, cell_size: 12, corner_radius: 100)
    svg = builder.build

    assert_includes svg, 'rx="6"'
  end

  # Tests for value-based calendar heatmap generation
  it "should convert values to scores using default linear formula" do
    date_values = {
      Date.new(2024, 1, 1) => 0,
      Date.new(2024, 1, 2) => 50,
      Date.new(2024, 1, 3) => 100
    }

    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(
      values: date_values,
      value_min: 0,
      value_max: 100
    )
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_default_formula.svg")
  end

  it "should handle missing dates by normalizing to minimum" do
    date_values = {
      Date.new(2024, 1, 1) => 50,
      Date.new(2024, 1, 3) => 100
    }

    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(
      values: date_values,
      value_min: 0,
      value_max: 100
    )
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_missing_dates.svg")
  end

  it "should auto-calculate value_min and value_max from calendar data" do
    date_values = {
      Date.new(2024, 1, 1) => 10,
      Date.new(2024, 1, 2) => 20,
      Date.new(2024, 1, 3) => 30
    }

    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(values: date_values)
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_auto_boundaries.svg")
  end

  it "should accept custom value_to_score callable for calendar" do
    # Custom formula: always return score 2
    custom_fn = ->(value:, date:, min:, max:, num_scores:) { 2 }

    date_values = {
      Date.new(2024, 1, 1) => 10,
      Date.new(2024, 1, 2) => 20
    }

    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(
      values: date_values,
      value_to_score: custom_fn
    )
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_custom_formula.svg")
  end

  it "should pass date parameter to custom value_to_score" do
    received_params = []
    custom_fn = ->(value:, date:, min:, max:, num_scores:) {
      received_params << {value: value, date: date, min: min, max: max, num_scores: num_scores}
      0
    }

    date1 = Date.new(2024, 1, 1)
    date2 = Date.new(2024, 1, 2)
    date_values = {
      date1 => 10,
      date2 => 20
    }

    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(
      values: date_values,
      value_min: 0,
      value_max: 100,
      value_to_score: custom_fn
    )
    builder.build

    assert_equal 2, received_params.length
    assert_equal 10, received_params[0][:value]
    assert_equal date1, received_params[0][:date]
    assert_equal 0, received_params[0][:min]
    assert_equal 100, received_params[0][:max]
  end

  it "should handle string date keys in values hash" do
    date_values = {
      "2024-01-01" => 10,
      "2024-01-02" => 20
    }

    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(values: date_values)
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_string_dates.svg")
  end

  it "should raise error if both scores and values provided for calendar" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(
        scores: {Date.new(2024, 1, 1) => 1},
        values: {Date.new(2024, 1, 1) => 10}
      )
    end
  end

  it "should handle empty values hash for calendar" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(values: {})
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_empty.svg")
  end
end
