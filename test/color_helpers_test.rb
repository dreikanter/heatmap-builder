require "test_helper"

class ColorHelpersTest < Minitest::Test
  def setup
    @builder = HeatmapBuilder::LinearHeatmapBuilder.new([1])
  end

  # Tests for OKLCH color conversion
  def test_rgb_to_oklch_conversion
    # Test with pure red
    oklch = @builder.send(:rgb_to_oklch, 255, 0, 0)

    assert_in_delta 0.63, oklch[0], 0.05  # L (lightness)
    assert_in_delta 0.26, oklch[1], 0.05  # C (chroma)
    assert_in_delta 29.0, oklch[2], 5.0   # H (hue in degrees)
  end

  def test_oklch_to_rgb_conversion
    # Test conversion back from OKLCH
    oklch = [0.63, 0.26, 29.0]  # Approximately red
    rgb = @builder.send(:oklch_to_rgb, *oklch)

    assert_in_delta 255, rgb[0], 10  # R
    assert_in_delta 0, rgb[1], 10    # G
    assert_in_delta 0, rgb[2], 10    # B
  end

  def test_hex_to_rgb_conversion
    rgb = @builder.send(:hex_to_rgb, "#ff0000")
    assert_equal [255, 0, 0], rgb

    rgb = @builder.send(:hex_to_rgb, "#00ff00")
    assert_equal [0, 255, 0], rgb
  end

  def test_rgb_to_hex_conversion
    hex = @builder.send(:rgb_to_hex, 255, 0, 0)
    assert_equal "#ff0000", hex

    hex = @builder.send(:rgb_to_hex, 0, 255, 0)
    assert_equal "#00ff00", hex
  end

  # Tests for OKLCH-based color operations
  def test_darker_color_maintains_hue
    original = "#ff0000"  # Red
    darker = @builder.send(:darker_color, original)

    refute_equal original, darker
    assert_match /^#[0-9a-f]{6}$/, darker  # Valid hex color

    # Should be darker (lower lightness)
    original_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, original))
    darker_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, darker))

    assert darker_oklch[0] < original_oklch[0]  # Lower lightness
    assert_in_delta original_oklch[2], darker_oklch[2], 5.0  # Hue should be preserved
  end

  def test_make_color_inactive_creates_muted_version
    original = "#0000ff"  # Blue
    inactive = @builder.send(:make_color_inactive, original)

    refute_equal original, inactive
    assert_match /^#[0-9a-f]{6}$/, inactive  # Valid hex color

    # Should be more muted (lower chroma)
    original_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, original))
    inactive_oklch = @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, inactive))

    assert inactive_oklch[1] < original_oklch[1]  # Lower chroma (more muted)
    assert_in_delta original_oklch[2], inactive_oklch[2], 5.0  # Hue should be preserved
  end

  def test_generate_color_palette_creates_gradient
    colors = @builder.send(:generate_color_palette, "#ffffff", "#000000", 5)

    assert_equal 5, colors.length
    assert_equal "#ffffff", colors.first   # Start color
    assert_equal "#000000", colors.last    # End color

    # Colors should be valid hex
    colors.each do |color|
      assert_match /^#[0-9a-f]{6}$/, color
    end

    # Should create a smooth gradient (lightness should decrease)
    oklchs = colors.map { |c| @builder.send(:rgb_to_oklch, *@builder.send(:hex_to_rgb, c)) }
    oklchs.each_cons(2) do |oklch1, oklch2|
      assert oklch2[0] <= oklch1[0], "Lightness should decrease or stay same"
    end
  end

  def test_interpolate_oklch_creates_midpoint
    oklch1 = [0, 0, 0]    # Black in OKLCH
    oklch2 = [1, 0, 0]    # White in OKLCH

    midpoint = @builder.send(:interpolate_oklch, oklch1, oklch2, 0.5)

    assert_equal [0.5, 0, 0], midpoint  # Midpoint
  end

  def test_interpolate_oklch_handles_hue_wraparound
    # Test interpolation across the 0/360 degree boundary
    oklch1 = [0.5, 0.2, 350]  # Near red
    oklch2 = [0.5, 0.2, 10]   # Also near red, but across the boundary

    midpoint = @builder.send(:interpolate_oklch, oklch1, oklch2, 0.5)

    # Should take the shorter path (average = 0 degrees, which becomes 360)
    assert_in_delta 0, midpoint[2] % 360, 5  # Should be close to 0/360
  end

  def test_score_to_color_with_generated_palette
    colors = { from: "#ffffff", to: "#ff0000", steps: 3 }

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

  def test_score_to_color_with_array_colors
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