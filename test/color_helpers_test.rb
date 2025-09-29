require "test_helper"

describe HeatmapBuilder::ColorHelpers do
  before do
    @builder = HeatmapBuilder::LinearHeatmapBuilder.new([1])
  end

  def valid_hex_color
    /^#[0-9a-f]{6}$/
  end

  # Tests for OKLCH color conversion
  it "#rgb_to_oklch should convert RGB to OKLCH color space" do
    # Test with pure red
    oklch = @builder.send(:rgb_to_oklch, 255, 0, 0)

    assert_in_delta 0.63, oklch[0], 0.05  # L (lightness)
    assert_in_delta 0.26, oklch[1], 0.05  # C (chroma)
    assert_in_delta 29.0, oklch[2], 5.0   # H (hue in degrees)
  end

  it "#oklch_to_rgb should convert OKLCH back to RGB" do
    # Test conversion back from OKLCH
    oklch = [0.63, 0.26, 29.0]  # Approximately red
    rgb = @builder.send(:oklch_to_rgb, *oklch)

    assert_in_delta 255, rgb[0], 10  # R
    assert_in_delta 0, rgb[1], 10    # G
    assert_in_delta 0, rgb[2], 10    # B
  end

  it "#hex_to_rgb should convert hex colors to RGB arrays" do
    rgb = @builder.send(:hex_to_rgb, "#ff0000")
    assert_equal [255, 0, 0], rgb

    rgb = @builder.send(:hex_to_rgb, "#00ff00")
    assert_equal [0, 255, 0], rgb
  end

  it "#rgb_to_hex should convert RGB values to hex strings" do
    hex = @builder.send(:rgb_to_hex, 255, 0, 0)
    assert_equal "#ff0000", hex

    hex = @builder.send(:rgb_to_hex, 0, 255, 0)
    assert_equal "#00ff00", hex
  end

  # Tests for OKLCH-based color operations
  it "#darker_color should maintain hue while reducing lightness" do
    original = "#ff0000"  # Red
    darker = @builder.send(:darker_color, original)

    refute_equal original, darker
    assert_match(valid_hex_color, darker)

    # Should be darker (lower lightness)
    original_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, original))
    darker_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, darker))

    assert darker_oklch[0] < original_oklch[0]  # Lower lightness
    assert_in_delta original_oklch[2], darker_oklch[2], 5.0  # Hue should be preserved
  end

  it "#make_color_inactive should create muted version by reducing chroma" do
    original = "#0000ff"
    inactive = @builder.send(:make_color_inactive, original)

    refute_equal original, inactive
    assert_match(valid_hex_color, inactive)

    # Should be more muted (lower chroma)
    original_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, original))
    inactive_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, inactive))

    assert inactive_oklch[1] < original_oklch[1]  # Lower chroma (more muted)
    assert_in_delta original_oklch[2], inactive_oklch[2], 5.0  # Hue should be preserved
  end

  it "#generate_color_palette should create smooth gradient between colors" do
    colors = @builder.send(:generate_color_palette, "#ffffff", "#000000", 5)

    assert_equal 5, colors.length
    assert_equal "#ffffff", colors.first
    assert_equal "#000000", colors.last

    # Colors should be valid hex
    colors.each do |color|
      assert_match(valid_hex_color, color)
    end

    # Should create a smooth gradient (lightness should decrease)
    oklchs = colors.map { |c| @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, c)) }
    oklchs.each_cons(2) do |oklch1, oklch2|
      assert oklch2[0] <= oklch1[0], "Lightness should decrease or stay same"
    end
  end

  it "#interpolate_oklch should create midpoint between two OKLCH colors" do
    oklch1 = [0, 0, 0]    # Black in OKLCH
    oklch2 = [1, 0, 0]    # White in OKLCH

    midpoint = @builder.send(:interpolate_oklch, oklch1, oklch2, 0.5)

    assert_equal [0.5, 0, 0], midpoint  # Midpoint
  end

  it "#interpolate_oklch should handle hue wraparound across 0/360 boundary" do
    # Test interpolation across the 0/360 degree boundary
    oklch1 = [0.5, 0.2, 350]  # Near red
    oklch2 = [0.5, 0.2, 10]   # Also near red, but across the boundary

    midpoint = @builder.send(:interpolate_oklch, oklch1, oklch2, 0.5)

    # Should take the shorter path (average = 0 degrees, which becomes 360)
    assert_in_delta 0, midpoint[2] % 360, 5  # Should be close to 0/360
  end

  it "#score_to_color should work with generated color palette" do
    colors = {from: "#ffffff", to: "#ff0000", steps: 3}

    # Score 0 should use first color (from)
    color = @builder.send(:score_to_color, 0, colors: colors)
    assert_equal "#ffffff", color

    # Score 1 should use second color
    color = @builder.send(:score_to_color, 1, colors: colors)
    refute_equal "#ffffff", color
    refute_equal "#ff0000", color  # Should be interpolated

    # Score 2 should use third color (to)
    color = @builder.send(:score_to_color, 2, colors: colors)
    assert_equal "#ff0000", color
  end

  it "#score_to_color should work with array of colors" do
    colors = ["#ffffff", "#ff0000", "#00ff00"]

    # Score 0 should use first color
    color = @builder.send(:score_to_color, 0, colors: colors)
    assert_equal "#ffffff", color

    # Score 1 should use second color
    color = @builder.send(:score_to_color, 1, colors: colors)
    assert_equal "#ff0000", color

    # Score 2 should use third color
    color = @builder.send(:score_to_color, 2, colors: colors)
    assert_equal "#00ff00", color
  end
end
