module HeatmapBuilder
  module ColorHelpers
    private

    def score_to_color(score, colors:)
      # Generate color palette if colors is a hash
      if colors.is_a?(Hash)
        colors = generate_color_palette(colors[:from], colors[:to], colors[:steps])
      end

      return colors.first if score == 0

      max_color_index = colors.length - 1
      color_index = 1 + (score - 1) % max_color_index
      colors[color_index]
    end

    def darker_color(hex_color, factor: 0.7)
      rgb = hex_to_rgb(hex_color)
      lab = rgb_to_lab(*rgb)

      # Reduce lightness (L component) by factor
      darker_lab = [lab[0] * factor, lab[1], lab[2]]
      darker_rgb = lab_to_rgb(*darker_lab)

      rgb_to_hex(*darker_rgb)
    end

    def make_color_inactive(hex_color)
      # Convert to LAB for blending
      rgb = hex_to_rgb(hex_color)
      lab = rgb_to_lab(*rgb)

      # Light gray target in LAB space
      gray_lab = rgb_to_lab(230, 230, 230)

      # Blend in LAB space - 60% original color, 40% gray
      mix_ratio = 0.6
      blended_lab = interpolate_lab(gray_lab, lab, mix_ratio)
      blended_rgb = lab_to_rgb(*blended_lab)

      rgb_to_hex(*blended_rgb)
    end

    def rgb_to_lab(r, g, b)
      # Normalize RGB to 0-1
      r, g, b = r / 255.0, g / 255.0, b / 255.0

      # Gamma correction (sRGB → linear RGB)
      r = (r > 0.04045) ? ((r + 0.055) / 1.055)**2.4 : r / 12.92
      g = (g > 0.04045) ? ((g + 0.055) / 1.055)**2.4 : g / 12.92
      b = (b > 0.04045) ? ((b + 0.055) / 1.055)**2.4 : b / 12.92

      # Convert to XYZ (using D65 illuminant)
      x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047
      y = (r * 0.2126729 + g * 0.7151522 + b * 0.0721750) / 1.0
      z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883

      # XYZ to LAB
      fx = (x > 0.008856) ? x**(1.0 / 3) : (7.787 * x + 16.0 / 116)
      fy = (y > 0.008856) ? y**(1.0 / 3) : (7.787 * y + 16.0 / 116)
      fz = (z > 0.008856) ? z**(1.0 / 3) : (7.787 * z + 16.0 / 116)

      l = 116 * fy - 16
      a = 500 * (fx - fy)
      b_lab = 200 * (fy - fz)

      [l, a, b_lab]
    end

    def lab_to_rgb(l, a, b_lab)
      # LAB to XYZ
      fy = (l + 16) / 116.0
      fx = a / 500.0 + fy
      fz = fy - b_lab / 200.0

      x = (fx**3 > 0.008856) ? fx**3 : (fx - 16.0 / 116) / 7.787
      y = (fy**3 > 0.008856) ? fy**3 : (fy - 16.0 / 116) / 7.787
      z = (fz**3 > 0.008856) ? fz**3 : (fz - 16.0 / 116) / 7.787

      # Apply D65 illuminant
      x *= 0.95047
      y *= 1.0
      z *= 1.08883

      # XYZ to linear RGB
      r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
      g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
      b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

      # Linear RGB to sRGB (gamma correction)
      r = (r > 0.0031308) ? 1.055 * (r**(1.0 / 2.4)) - 0.055 : 12.92 * r
      g = (g > 0.0031308) ? 1.055 * (g**(1.0 / 2.4)) - 0.055 : 12.92 * g
      b = (b > 0.0031308) ? 1.055 * (b**(1.0 / 2.4)) - 0.055 : 12.92 * b

      # Clamp to 0-255 and convert to integers
      r = (r * 255).clamp(0, 255).round
      g = (g * 255).clamp(0, 255).round
      b = (b * 255).clamp(0, 255).round

      [r, g, b]
    end

    def interpolate_lab(lab1, lab2, ratio)
      [
        lab1[0] + (lab2[0] - lab1[0]) * ratio, # L
        lab1[1] + (lab2[1] - lab1[1]) * ratio, # A
        lab1[2] + (lab2[2] - lab1[2]) * ratio  # B
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

    def generate_color_palette(from_color, to_color, steps)
      from_rgb = hex_to_rgb(from_color)
      to_rgb = hex_to_rgb(to_color)

      from_lab = rgb_to_lab(*from_rgb)
      to_lab = rgb_to_lab(*to_rgb)

      colors = []
      (0...steps).each do |i|
        ratio = i.to_f / (steps - 1)
        interpolated_lab = interpolate_lab(from_lab, to_lab, ratio)
        interpolated_rgb = lab_to_rgb(*interpolated_lab)
        colors << rgb_to_hex(*interpolated_rgb)
      end

      colors
    end
  end
end
