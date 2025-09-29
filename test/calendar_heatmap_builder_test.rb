require "test_helper"

describe HeatmapBuilder::CalendarHeatmapBuilder do
  before do
    @scores = {
      "2024-01-01" => 1,
      "2024-01-02" => 2,
      "2024-01-03" => 0,
      "2024-01-07" => 3
    }
    @builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores)
  end

  it "should build SVG with default options" do
    svg = @builder.build

    assert_matches_snapshot(svg, "calendar_basic.svg")
  end

  it "should generate calendar grid with rect elements" do
    svg = @builder.build

    # Should contain rect elements for calendar cells
    assert_includes svg, "<rect"
    assert_includes svg, "fill=\"#"
  end

  it "should use Monday as start of week when specified" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, start_of_week: :monday)
    svg = builder.build

    # Should include day labels starting with Monday
    assert_includes svg, ">M</text>"
  end

  it "should use Sunday as start of week when specified" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, start_of_week: :sunday)
    svg = builder.build

    # Should include day labels starting with Sunday
    assert_includes svg, ">S</text>"
  end

  it "should display month labels when enabled" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, show_month_labels: true)
    svg = builder.build

    # Should include month label for January
    assert_includes svg, ">Jan</text>"
  end

  it "should display day labels when enabled" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, show_day_labels: true)
    svg = builder.build

    # Should include day labels
    assert_includes svg, ">M</text>"
    assert_includes svg, ">T</text>"
  end

  it "should use custom colors when provided" do
    colors = %w[#ffffff #ff0000 #00ff00]
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, colors: colors)
    svg = builder.build

    assert_includes svg, "fill=\"#ffffff\""
    assert_includes svg, "fill=\"#ff0000\""
  end

  it "should raise errors for invalid inputs" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new("invalid")
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, cell_size: 0)
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, colors: [])
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, start_of_week: :invalid)
    end
  end

  it "should accept Date objects as keys" do
    date_scores = {
      Date.new(2024, 1, 1) => 1,
      Date.new(2024, 1, 2) => 2
    }
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(date_scores)
    svg = builder.build

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  it "should handle empty scores hash" do
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new({})
    svg = builder.build

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end
end