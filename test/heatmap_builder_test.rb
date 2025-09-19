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

  def test_respects_cells_per_row_limit
    scores = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    svg = HeatmapBuilder.generate(scores, cells_per_row: 3)

    # Should only render first 3 cells
    assert_includes svg, ">1</text>"
    assert_includes svg, ">2</text>"
    assert_includes svg, ">3</text>"
    refute_includes svg, ">4</text>"
  end
end
