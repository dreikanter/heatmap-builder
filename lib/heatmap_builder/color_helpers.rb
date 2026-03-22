module HeatmapBuilder
  module ColorHelpers
    class << self
      def score_to_color(score, colors:)
        return colors.first if score == 0

        max_color_index = colors.length - 1
        color_index = 1 + (score - 1) % max_color_index
        colors[color_index]
      end

      def darker_color(hex_color, factor: 0.9)
        rgb = hex_to_rgb(hex_color)
        oklch = rgb_to_oklch(*rgb)

        darker_oklch = [oklch[0] * factor, oklch[1], oklch[2]]
        darker_rgb = oklch_to_rgb(*darker_oklch)

        rgb_to_hex(*darker_rgb)
      end

      def make_color_inactive(hex_color)
        rgb = hex_to_rgb(hex_color)
        oklch = rgb_to_oklch(*rgb)

        inactive_oklch = [
          oklch[0] * 0.85, # Slightly reduce lightness
          oklch[1] * 0.4,  # Significantly reduce chroma (saturation)
          oklch[2]         # Keep hue unchanged
        ]

        inactive_rgb = oklch_to_rgb(*inactive_oklch)
        rgb_to_hex(*inactive_rgb)
      end

      def generate_color_palette(from_color, to_color, steps)
        from_rgb = hex_to_rgb(from_color)
        to_rgb = hex_to_rgb(to_color)

        from_oklch = rgb_to_oklch(*from_rgb)
        to_oklch = rgb_to_oklch(*to_rgb)

        colors = []
        (0...steps).each do |i|
          ratio = i.to_f / (steps - 1)
          interpolated_oklch = interpolate_oklch(from_oklch, to_oklch, ratio)
          interpolated_rgb = oklch_to_rgb(*interpolated_oklch)
          colors << rgb_to_hex(*interpolated_rgb)
        end

        colors
      end

      private

      def rgb_to_oklch(r, g, b)
        r_linear = srgb_to_linear(r / 255.0)
        g_linear = srgb_to_linear(g / 255.0)
        b_linear = srgb_to_linear(b / 255.0)

        l = 0.4122214708 * r_linear + 0.5363325363 * g_linear + 0.0514459929 * b_linear
        m = 0.2119034982 * r_linear + 0.6806995451 * g_linear + 0.1073969566 * b_linear
        s = 0.0883024619 * r_linear + 0.2817188376 * g_linear + 0.6299787005 * b_linear

        l_root = (l >= 0) ? l**(1.0 / 3) : -((-l)**(1.0 / 3))
        m_root = (m >= 0) ? m**(1.0 / 3) : -((-m)**(1.0 / 3))
        s_root = (s >= 0) ? s**(1.0 / 3) : -((-s)**(1.0 / 3))

        ok_l = 0.2104542553 * l_root + 0.7936177850 * m_root - 0.0040720468 * s_root
        ok_a = 1.9779984951 * l_root - 2.4285922050 * m_root + 0.4505937099 * s_root
        ok_b = 0.0259040371 * l_root + 0.7827717662 * m_root - 0.8086757660 * s_root

        chroma = Math.sqrt(ok_a * ok_a + ok_b * ok_b)
        hue = Math.atan2(ok_b, ok_a) * 180.0 / Math::PI
        hue += 360 if hue < 0

        [ok_l, chroma, hue]
      end

      def oklch_to_rgb(ok_l, chroma, hue)
        hue_rad = hue * Math::PI / 180.0
        ok_a = chroma * Math.cos(hue_rad)
        ok_b = chroma * Math.sin(hue_rad)

        l_root = ok_l + 0.3963377774 * ok_a + 0.2158037573 * ok_b
        m_root = ok_l - 0.1055613458 * ok_a - 0.0638541728 * ok_b
        s_root = ok_l - 0.0894841775 * ok_a - 1.2914855480 * ok_b

        l = l_root * l_root * l_root
        m = m_root * m_root * m_root
        s = s_root * s_root * s_root

        r_linear = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        g_linear = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        b_linear = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        r = linear_to_srgb(r_linear)
        g = linear_to_srgb(g_linear)
        b = linear_to_srgb(b_linear)

        r = (r * 255).clamp(0, 255).round
        g = (g * 255).clamp(0, 255).round
        b = (b * 255).clamp(0, 255).round

        [r, g, b]
      end

      def srgb_to_linear(component)
        (component <= 0.04045) ? component / 12.92 : ((component + 0.055) / 1.055)**2.4
      end

      def linear_to_srgb(component)
        (component <= 0.0031308) ? component * 12.92 : 1.055 * (component**(1.0 / 2.4)) - 0.055
      end

      def interpolate_oklch(oklch1, oklch2, ratio)
        hue1, hue2 = oklch1[2], oklch2[2]
        hue_diff = hue2 - hue1

        if hue_diff > 180
          hue_diff -= 360
        elsif hue_diff < -180
          hue_diff += 360
        end

        interpolated_hue = hue1 + hue_diff * ratio
        interpolated_hue += 360 if interpolated_hue < 0
        interpolated_hue -= 360 if interpolated_hue >= 360

        [
          oklch1[0] + (oklch2[0] - oklch1[0]) * ratio,
          oklch1[1] + (oklch2[1] - oklch1[1]) * ratio,
          interpolated_hue
        ]
      end

      def hex_to_rgb(hex_color)
        hex = hex_color.delete("#")
        r = hex[0..1].to_i(16)
        g = hex[2..3].to_i(16)
        b = hex[4..5].to_i(16)
        [r, g, b]
      end

      def rgb_to_hex(r, g, b)
        "#%02x%02x%02x" % [r, g, b]
      end
    end
  end
end
