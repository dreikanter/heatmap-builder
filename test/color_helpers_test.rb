require "test_helper"

describe HeatmapBuilder::ColorHelpers do
  def valid_hex_color
    /^#[0-9a-f]{6}$/
  end

  it ".darker_color should maintain hue while reducing lightness" do
    original = "#ff0000"
    darker = HeatmapBuilder::ColorHelpers.darker_color(original)

    refute_equal original, darker
    assert_match(valid_hex_color, darker)
  end

  it ".make_color_inactive should create muted version" do
    original = "#0000ff"
    inactive = HeatmapBuilder::ColorHelpers.make_color_inactive(original)

    refute_equal original, inactive
    assert_match(valid_hex_color, inactive)
  end

  it ".generate_color_palette should create smooth gradient between colors" do
    colors = HeatmapBuilder::ColorHelpers.generate_color_palette("#ffffff", "#000000", 5)

    assert_equal 5, colors.length
    assert_equal "#ffffff", colors.first
    assert_equal "#000000", colors.last

    colors.each do |color|
      assert_match(valid_hex_color, color)
    end
  end

  it ".score_to_color should return first color for score 0" do
    colors = %w[#ffffff #ff0000 #00ff00]

    assert_equal "#ffffff", HeatmapBuilder::ColorHelpers.score_to_color(0, colors: colors)
  end

  it ".score_to_color should map scores to palette colors" do
    colors = %w[#ffffff #ff0000 #00ff00]

    assert_equal "#ff0000", HeatmapBuilder::ColorHelpers.score_to_color(1, colors: colors)
    assert_equal "#00ff00", HeatmapBuilder::ColorHelpers.score_to_color(2, colors: colors)
  end

  it ".score_to_color should work with generated palette" do
    colors = HeatmapBuilder::ColorHelpers.generate_color_palette("#ffffff", "#ff0000", 3)

    assert_equal "#ffffff", HeatmapBuilder::ColorHelpers.score_to_color(0, colors: colors)
    assert_equal "#ff0000", HeatmapBuilder::ColorHelpers.score_to_color(2, colors: colors)

    mid = HeatmapBuilder::ColorHelpers.score_to_color(1, colors: colors)
    refute_equal "#ffffff", mid
    refute_equal "#ff0000", mid
  end
end
