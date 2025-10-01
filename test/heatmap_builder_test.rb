require "test_helper"

describe HeatmapBuilder do
  it "should have a version number" do
    refute_nil ::HeatmapBuilder::VERSION
  end

  it ".build_linear should delegate to LinearHeatmapBuilder" do
    svg = HeatmapBuilder.build_linear(scores: [0])

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  it ".build_calendar should delegate to CalendarHeatmapBuilder" do
    scores_by_date = {"2024-01-01" => 1}
    svg = HeatmapBuilder.build_calendar(scores: scores_by_date)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  # Tests for backward compatibility
  it ".generate should work and show deprecation warning" do
    svg = nil
    _out, err = capture_io do
      svg = HeatmapBuilder.generate([1], {cell_size: 20})
    end

    assert_includes err, "DEPRECATION"
    assert_matches_snapshot(svg, "linear_backward_compat.svg")
  end

  it ".generate_calendar should work and show deprecation warning" do
    scores_by_date = {"2024-01-01" => 1}
    svg = nil
    _out, err = capture_io do
      svg = HeatmapBuilder.generate_calendar(scores_by_date, {cell_size: 15})
    end

    assert_includes err, "DEPRECATION"
    assert_matches_snapshot(svg, "calendar_backward_compat.svg")
  end
end
