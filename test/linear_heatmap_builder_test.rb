require "test_helper"

describe HeatmapBuilder::LinearHeatmapBuilder do
  before do
    @builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2, 3])
  end

  it "should use default options when none provided" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1])
    svg = builder.build

    assert_includes svg, "width=\"10\""  # cell_size only
    assert_includes svg, "font-size=\"8\""
    assert_includes svg, "height=\"10\""  # cell_size only
  end

  it "should respect custom text color when provided" do
    # Test that custom text color is respected
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1], text_color: "#ff0000")
    svg = builder.build
    assert_includes svg, "fill=\"#ff0000\""
  end

  it "should apply custom cell spacing" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2], cell_spacing: 5)
    svg = builder.build

    # Second cell should be at x = cell_size + spacing = 10 + 5 = 15
    assert_includes svg, "x=\"15\""
  end

  it "should calculate correct SVG dimensions" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2, 3],
      cell_size: 15, cell_spacing: 3, border_width: 1)
    svg = builder.build

    # Width = 3 * 15 + 2 * 3 = 51 (3 cells, 2 spacings)
    assert_includes svg, "width=\"51\""
    # Height = cell_size = 15
    assert_includes svg, "height=\"15\""
  end

  it "should raise errors for invalid inputs" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new(scores: "invalid")
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1], cell_size: 0)
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1], colors: [])
    end
  end

  it "should cycle through colors for large scores" do
    colors = %w[#ebedf0 #9be9a8 #40c463]
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2, 3], colors: colors)
    svg = builder.build

    # Scores should cycle through non-zero colors
    assert_includes svg, 'fill="#9be9a8"'
    assert_includes svg, 'fill="#40c463"'
  end

  it "should apply corner_radius to cells" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2], corner_radius: 3)
    svg = builder.build

    assert_includes svg, 'rx="3"'
  end

  it "should not include rx attribute when corner_radius is 0" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2], corner_radius: 0)
    svg = builder.build

    refute_includes svg, "rx="
  end

  it "should normalize corner_radius to maximum allowed value" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1], cell_size: 10, corner_radius: 100)
    svg = builder.build

    assert_includes svg, 'rx="5"'
  end

  it "should normalize negative corner_radius to 0" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1], corner_radius: -5)
    svg = builder.build

    refute_includes svg, "rx="
  end

  # Tests for value-based heatmap generation
  it "should convert values to scores using default linear formula" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [0, 50, 100], value_min: 0, value_max: 100)
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_default_formula.svg")
  end

  it "should handle nil values by normalizing to minimum" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [nil, 50, 100], value_min: 0, value_max: 100)
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_with_nil.svg")
  end

  it "should auto-calculate value_min and value_max from data" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [10, 20, 30])
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_auto_boundaries.svg")
  end

  it "should clamp values below value_min" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [-10, 50, 100], value_min: 0, value_max: 100)
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_clamp_min.svg")
  end

  it "should clamp values above value_max" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [0, 50, 150], value_min: 0, value_max: 100)
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_clamp_max.svg")
  end

  it "should handle all values equal (min == max)" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [50, 50, 50], value_min: 50, value_max: 50)
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_equal.svg")
  end

  it "should raise error if value_min > value_max" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new(values: [1, 2, 3], value_min: 100, value_max: 0)
    end
  end

  it "should raise error if both scores and values provided" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1, 2, 3], values: [10, 20, 30])
    end
  end

  it "should accept custom value_to_score callable" do
    # Custom formula: always return score 2
    custom_fn = ->(value:, index:, min:, max:, num_scores:) { 2 }

    builder = HeatmapBuilder::LinearHeatmapBuilder.new(
      values: [10, 20, 30],
      value_to_score: custom_fn
    )
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_custom_formula.svg")
  end

  it "should validate custom value_to_score returns valid integer" do
    # Custom formula returns invalid value
    custom_fn = ->(value:, index:, min:, max:, num_scores:) { 999 }

    builder = HeatmapBuilder::LinearHeatmapBuilder.new(
      values: [10, 20, 30],
      value_to_score: custom_fn
    )

    assert_raises(HeatmapBuilder::Error) do
      builder.build
    end
  end

  it "should pass correct parameters to custom value_to_score" do
    received_params = []
    custom_fn = ->(value:, index:, min:, max:, num_scores:) {
      received_params << {value: value, index: index, min: min, max: max, num_scores: num_scores}
      0
    }

    builder = HeatmapBuilder::LinearHeatmapBuilder.new(
      values: [10, 20],
      value_min: 0,
      value_max: 100,
      value_to_score: custom_fn
    )
    builder.build

    assert_equal 2, received_params.length
    assert_equal 10, received_params[0][:value]
    assert_equal 0, received_params[0][:index]
    assert_equal 0, received_params[0][:min]
    assert_equal 100, received_params[0][:max]
    assert_equal 5, received_params[0][:num_scores]  # Default GITHUB_GREEN has 5 colors
  end

  it "should handle empty values array" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(values: [])
    svg = builder.build

    assert_matches_snapshot(svg, "linear_values_empty.svg")
  end

  it "should work with hash-based color palette" do
    builder = HeatmapBuilder::LinearHeatmapBuilder.new(
      scores: [0, 1, 2],
      colors: {from: "#ffffff", to: "#ff0000", steps: 3}
    )
    svg = builder.build

    assert_includes svg, "<svg"
    assert_includes svg, "</svg>"
  end

  it "should raise error for invalid colors option" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::LinearHeatmapBuilder.new(scores: [1], colors: "invalid")
    end
  end
end
