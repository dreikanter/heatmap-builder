require "test_helper"

describe HeatmapBuilder do
  it "should have a version number" do
    refute_nil ::HeatmapBuilder::VERSION
  end

  it ".generate should create basic SVG" do
    scores = [0, 1, 2, 3, 4]
    svg = HeatmapBuilder.generate(scores)

    assert_matches_snapshot(svg, "linear_basic.svg")
  end

  it ".generate should create SVG with score text" do
    scores = [5, 10, 15]
    svg = HeatmapBuilder.generate(scores)

    assert_matches_snapshot(svg, "linear_with_text.svg")
  end

  it ".generate should accept custom options" do
    scores = [1, 2, 3]
    options = {
      cell_size: 30,
      font_size: 14,
      colors: %w[#ffffff #ff0000 #00ff00 #0000ff]
    }
    svg = HeatmapBuilder.generate(scores, options)

    assert_matches_snapshot(svg, "linear_custom_options.svg")
  end

  it ".generate should include score text in SVG" do
    scores = [5, 10, 15]
    svg = HeatmapBuilder.generate(scores)

    assert_includes svg, ">5</text>"
    assert_includes svg, ">10</text>"
    assert_includes svg, ">15</text>"
  end

  it ".generate should handle empty scores array" do
    svg = HeatmapBuilder.generate([])
    assert_matches_snapshot(svg, "linear_empty.svg")
  end

  it ".generate should raise error for invalid scores" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.generate("not an array")
    end
  end

  it ".generate should raise error for invalid cell size" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.generate([1, 2, 3], cell_size: -1)
    end
  end

  it ".generate should raise error for insufficient colors" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.generate([1, 2, 3], colors: ["#ffffff"])
    end
  end

  # Tests for new object color format
  it ".build_linear should work with object color format" do
    scores = [0, 1, 2, 3, 4]  # Start with 0 to get the first color
    svg = HeatmapBuilder.build_linear(scores, colors: {from: "#ffffff", to: "#ff0000", steps: 5})

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
    assert_includes svg, "fill=\"#ffffff\""  # First color (from) when score is 0
  end

  it ".build_linear should validate object color format missing keys" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: {from: "#fff"})
    end
  end

  it ".build_linear should validate object color format insufficient steps" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: {from: "#fff", to: "#000", steps: 1})
    end
  end

  it ".build_linear should validate object color format non-integer steps" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: {from: "#fff", to: "#000", steps: "5"})
    end
  end

  it ".build_linear should raise error for invalid colors format" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: "not valid")
    end
  end

  # Tests for fixed text color
  it ".build_linear should use black as default text color" do
    scores = [1]
    svg = HeatmapBuilder.build_linear(scores)

    assert_includes svg, "fill=\"#000000\""  # Default text color
  end

  it ".build_linear should use custom text color when provided" do
    scores = [1]
    svg = HeatmapBuilder.build_linear(scores, text_color: "#ffffff")

    assert_matches_snapshot(svg, "linear_custom_text_color.svg")
  end

  # Tests for calendar heatmap
  it ".build_calendar should generate SVG for calendar heatmap" do
    scores_by_date = {
      "2024-01-01" => 1,
      "2024-01-02" => 2,
      "2024-01-03" => 3
    }
    svg = HeatmapBuilder.build_calendar(scores_by_date)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  it ".build_calendar should validate input is a hash" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_calendar([1, 2, 3])
    end
  end

  it ".build_calendar should validate start_of_week option" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_calendar({}, start_of_week: :invalid)
    end
  end

  # Tests for backward compatibility aliases
  it ".generate alias should work for backward compatibility" do
    scores = [1, 2, 3]
    svg = HeatmapBuilder.generate(scores)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  it ".build alias should work for backward compatibility" do
    scores = [1, 2, 3]
    svg = HeatmapBuilder.build(scores)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  it ".generate_calendar alias should work for backward compatibility" do
    scores_by_date = {"2024-01-01" => 1}
    svg = HeatmapBuilder.generate_calendar(scores_by_date)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end
end
