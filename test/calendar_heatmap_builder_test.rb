require "test_helper"

class CalendarHeatmapBuilderTest < Minitest::Test
  def setup
    @scores = {
      "2024-01-01" => 1,
      "2024-01-02" => 2,
      "2024-01-03" => 0,
      "2024-01-07" => 3
    }
    @builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores)
  end

  def test_default_options
    svg = @builder.generate

    assert_includes svg, "<svg"
    assert_includes svg, "xmlns=\"http://www.w3.org/2000/svg\""
    assert_includes svg, "</svg>"
  end

  def test_generates_calendar_grid
    svg = @builder.generate

    # Should contain rect elements for calendar cells
    assert_includes svg, "<rect"
    assert_includes svg, "fill=\"#"
  end

  def test_start_of_week_monday
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, start_of_week: :monday)
    svg = builder.generate

    # Should include day labels starting with Monday
    assert_includes svg, ">M</text>"
  end

  def test_start_of_week_sunday
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, start_of_week: :sunday)
    svg = builder.generate

    # Should include day labels starting with Sunday
    assert_includes svg, ">S</text>"
  end

  def test_month_labels
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, show_month_labels: true)
    svg = builder.generate

    # Should include month label for January
    assert_includes svg, ">Jan</text>"
  end

  def test_day_labels
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, show_day_labels: true)
    svg = builder.generate

    # Should include day labels
    assert_includes svg, ">M</text>"
    assert_includes svg, ">T</text>"
  end

  def test_custom_colors
    colors = %w[#ffffff #ff0000 #00ff00]
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(@scores, colors: colors)
    svg = builder.generate

    assert_includes svg, "fill=\"#ffffff\""
    assert_includes svg, "fill=\"#ff0000\""
  end

  def test_validation_errors
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

  def test_date_objects_as_keys
    date_scores = {
      Date.new(2024, 1, 1) => 1,
      Date.new(2024, 1, 2) => 2
    }
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new(date_scores)
    svg = builder.generate

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  def test_empty_scores
    builder = HeatmapBuilder::CalendarHeatmapBuilder.new({})
    svg = builder.generate

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end
end
