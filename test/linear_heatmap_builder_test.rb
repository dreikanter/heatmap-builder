require "test_helper"

class LinearHeatmapBuilderTest < Minitest::Test
  def setup
    @builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2, 3])
  end

  def test_default_options
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1])
    svg = builder.generate

    assert_includes svg, "width=\"10\""  # cell_size only
    assert_includes svg, "font-size=\"8\""
    assert_includes svg, "height=\"10\""  # cell_size only
  end

  def test_score_to_color_mapping
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([0, 1, 2, 3, 4, 5])
    svg = builder.generate

    # Score 0 should use first color (gray)
    assert_includes svg, "fill=\"#ebedf0\""
    # Higher scores should use progressively greener colors
    assert_includes svg, "fill=\"#9be9a8\""
    assert_includes svg, "fill=\"#40c463\""
  end

  def test_text_color_contrast
    # Test with light background
    light_colors = %w[#ffffff #ebedf0 #9be9a8]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([0, 1, 2], colors: light_colors)
    svg = builder.generate
    assert_includes svg, "fill=\"#000000\""

    # Test with dark background
    dark_colors = %w[#000000 #216e39 #30a14e]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([0, 1, 2], colors: dark_colors)
    svg = builder.generate
    assert_includes svg, "fill=\"#ffffff\""
  end

  def test_custom_cell_spacing
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2], cell_spacing: 5)
    svg = builder.generate

    # Second cell should be at x = cell_size + spacing = 10 + 5 = 15
    assert_includes svg, "x=\"15\""
  end

  def test_svg_dimensions
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2, 3],
      cell_size: 15, cell_spacing: 3, border_width: 1)
    svg = builder.generate

    # Width = 3 * 15 + 2 * 3 = 51 (3 cells, 2 spacings)
    assert_includes svg, "width=\"51\""
    # Height = cell_size = 15
    assert_includes svg, "height=\"15\""
  end

  def test_validation_errors
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new("invalid")
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new([1], cell_size: 0)
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new([1], colors: [])
    end
  end

  def test_large_scores_cycle_colors
    colors = %w[#ebedf0 #9be9a8 #40c463]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2, 3], colors: colors)
    svg = builder.generate

    # Scores should cycle through non-zero colors
    assert_includes svg, 'fill="#9be9a8"'
    assert_includes svg, 'fill="#40c463"'
  end
end
