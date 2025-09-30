require "test_helper"

describe HeatmapBuilder::LinearHeatmapBuilder do
  before do
    @builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2, 3])
  end

  it "should use default options when none provided" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1])
    svg = builder.build

    assert_includes svg, "width=\"10\""  # cell_size only
    assert_includes svg, "font-size=\"8\""
    assert_includes svg, "height=\"10\""  # cell_size only
  end

  it "#score_to_color should map scores to appropriate colors" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([0, 1, 2, 3, 4, 5])
    svg = builder.build

    # Score 0 should use first color (gray)
    assert_includes svg, "fill=\"#ebedf0\""

    # Higher scores should use progressively greener colors
    assert_includes svg, "fill=\"#9be9a8\""
    assert_includes svg, "fill=\"#40c463\""
  end

  it "should use fixed text color regardless of background" do
    # Test with any background - text color should always be the default (#000000)
    light_colors = %w[#ffffff #ebedf0 #9be9a8]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([0, 1, 2], colors: light_colors)
    svg = builder.build
    assert_includes svg, "fill=\"#000000\""

    # Test with dark background - text color should still be default
    dark_colors = %w[#000000 #216e39 #30a14e]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([0, 1, 2], colors: dark_colors)
    svg = builder.build
    assert_includes svg, "fill=\"#000000\""
  end

  it "should respect custom text color when provided" do
    # Test that custom text color is respected
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1], text_color: "#ff0000")
    svg = builder.build
    assert_includes svg, "fill=\"#ff0000\""
  end

  it "should apply custom cell spacing" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2], cell_spacing: 5)
    svg = builder.build

    # Second cell should be at x = cell_size + spacing = 10 + 5 = 15
    assert_includes svg, "x=\"15\""
  end

  it "should calculate correct SVG dimensions" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2, 3],
      cell_size: 15, cell_spacing: 3, border_width: 1)
    svg = builder.build

    # Width = 3 * 15 + 2 * 3 = 51 (3 cells, 2 spacings)
    assert_includes svg, "width=\"51\""
    # Height = cell_size = 15
    assert_includes svg, "height=\"15\""
  end

  it "should raise errors for invalid inputs" do
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

  it "should cycle through colors for large scores" do
    colors = %w[#ebedf0 #9be9a8 #40c463]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2, 3], colors: colors)
    svg = builder.build

    # Scores should cycle through non-zero colors
    assert_includes svg, 'fill="#9be9a8"'
    assert_includes svg, 'fill="#40c463"'
  end

  it "should apply corner_radius to cells" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2], corner_radius: 3)
    svg = builder.build

    assert_includes svg, 'rx="3"'
  end

  it "should not include rx attribute when corner_radius is 0" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1, 2], corner_radius: 0)
    svg = builder.build

    refute_includes svg, 'rx='
  end

  it "should normalize corner_radius to maximum allowed value" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1], cell_size: 10, corner_radius: 100)
    svg = builder.build

    assert_includes svg, 'rx="5"'
  end

  it "should normalize negative corner_radius to 0" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new([1], corner_radius: -5)
    svg = builder.build

    refute_includes svg, 'rx='
  end
end
