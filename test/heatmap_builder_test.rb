require "test_helper"

describe HeatmapBuilder do
  it "should have a version number" do
    refute_nil ::HeatmapBuilder::VERSION
  end

  it ".build_calendar should delegate to Calendar" do
    scores_by_date = {"2024-01-01" => 1}
    svg = HeatmapBuilder.build_calendar(scores: scores_by_date)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  # Tests for backward compatibility
  it ".generate_calendar should work and show deprecation warning" do
    scores_by_date = {"2024-01-01" => 1}
    svg = nil
    _out, err = capture_io do
      svg = HeatmapBuilder.generate_calendar(scores_by_date, {cell_size: 15})
    end

    assert_includes err, "DEPRECATION"
    assert_matches_snapshot(svg, "calendar_backward_compat.svg")
  end

  describe "common validations" do
    it "should raise error for non-positive cell_size" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, cell_size: 0)
      end

      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, cell_size: -5)
      end
    end

    it "should raise error for non-positive font_size" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, font_size: 0)
      end

      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, font_size: -3)
      end
    end

    it "should raise error for colors array with less than 2 colors" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, colors: ["#ffffff"])
      end
    end

    it "should raise error for colors hash missing required keys" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, colors: {from: "#ffffff", to: "#000000"})
      end

      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, colors: {from: "#ffffff", steps: 3})
      end

      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, colors: {to: "#000000", steps: 3})
      end
    end

    it "should raise error for steps not being an Integer" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, colors: {from: "#ffffff", to: "#000000", steps: "3"})
      end
    end

    it "should raise error for steps less than 2" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: {"2024-01-01" => 1}, colors: {from: "#ffffff", to: "#000000", steps: 1})
      end
    end
  end
end
