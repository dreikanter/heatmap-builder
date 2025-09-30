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
end
