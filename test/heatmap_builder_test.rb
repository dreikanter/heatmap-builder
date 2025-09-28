require "test_helper"

class HeatmapBuilderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HeatmapBuilder::VERSION
  end

  def test_generate_basic_svg
    scores = [0, 1, 2, 3, 4]
    svg = HeatmapBuilder.generate(scores)

    assert_includes svg, "<svg"
    assert_includes svg, "xmlns=\"http://www.w3.org/2000/svg\""
    assert_includes svg, "</svg>"
  end

  def test_generate_with_custom_options
    scores = [1, 2, 3]
    options = {
      cell_size: 30,
      font_size: 14,
      colors: %w[#ffffff #ff0000 #00ff00 #0000ff]
    }
    svg = HeatmapBuilder.generate(scores, options)

    assert_includes svg, "width=\"30\""  # cell_size only
    assert_includes svg, "font-size=\"14\""
    assert_includes svg, "fill=\"#ff0000\""
  end

  def test_generate_includes_score_text
    scores = [5, 10, 15]
    svg = HeatmapBuilder.generate(scores)

    assert_includes svg, ">5</text>"
    assert_includes svg, ">10</text>"
    assert_includes svg, ">15</text>"
  end

  def test_empty_scores_array
    svg = HeatmapBuilder.generate([])
    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  def test_invalid_scores_raises_error
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.generate("not an array")
    end
  end

  def test_invalid_cell_size_raises_error
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.generate([1, 2, 3], cell_size: -1)
    end
  end

  def test_insufficient_colors_raises_error
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.generate([1, 2, 3], colors: ["#ffffff"])
    end
  end

  # Tests for new object color format
  def test_object_color_format_generates_svg
    scores = [0, 1, 2, 3, 4]  # Start with 0 to get the first color
    svg = HeatmapBuilder.build_linear(scores, colors: { from: "#ffffff", to: "#ff0000", steps: 5 })

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
    assert_includes svg, "fill=\"#ffffff\""  # First color (from) when score is 0
  end

  def test_object_color_format_validation_missing_keys
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: { from: "#fff" })
    end
  end

  def test_object_color_format_validation_insufficient_steps
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: { from: "#fff", to: "#000", steps: 1 })
    end
  end

  def test_object_color_format_validation_non_integer_steps
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: { from: "#fff", to: "#000", steps: "5" })
    end
  end

  def test_invalid_colors_format_raises_error
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_linear([1, 2, 3], colors: "not valid")
    end
  end

  # Tests for fixed text color
  def test_default_text_color_is_black
    scores = [1]
    svg = HeatmapBuilder.build_linear(scores)

    assert_includes svg, "fill=\"#000000\""  # Default text color
  end

  def test_custom_text_color_is_used
    scores = [1]
    svg = HeatmapBuilder.build_linear(scores, text_color: "#ffffff")

    assert_includes svg, "fill=\"#ffffff\""  # Custom text color
  end

  # Tests for calendar heatmap
  def test_calendar_heatmap_generates_svg
    scores_by_date = {
      "2024-01-01" => 1,
      "2024-01-02" => 2,
      "2024-01-03" => 3
    }
    svg = HeatmapBuilder.build_calendar(scores_by_date)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  def test_calendar_heatmap_validation_non_hash
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_calendar([1, 2, 3])
    end
  end

  def test_calendar_heatmap_validation_invalid_start_of_week
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder.build_calendar({}, start_of_week: :invalid)
    end
  end

  # Tests for backward compatibility aliases
  def test_generate_alias_works
    scores = [1, 2, 3]
    svg = HeatmapBuilder.generate(scores)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  def test_build_alias_works
    scores = [1, 2, 3]
    svg = HeatmapBuilder.build(scores)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  def test_generate_calendar_alias_works
    scores_by_date = { "2024-01-01" => 1 }
    svg = HeatmapBuilder.generate_calendar(scores_by_date)

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end
end
