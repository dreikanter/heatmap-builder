module HeatmapBuilder
  module SvgHelpers
    private

    def svg_element(tag, attributes = {}, &block)
      attr_string = attributes.map do |key, value|
        attr_name = kebab_case(key)
        "#{attr_name}=\"#{value}\""
      end.join(" ")
      attr_string = " #{attr_string}" unless attr_string.empty?

      if block_given?
        content = block.call
        "<#{tag}#{attr_string}>#{content}</#{tag}>"
      else
        "<#{tag}#{attr_string}/>"
      end
    end

    def svg_rect(x:, y:, width:, height:, **attributes)
      svg_element("rect", {x: x, y: y, width: width, height: height}.merge(attributes))
    end

    def svg_text(content, x:, y:, **attributes)
      default_attrs = {
        text_anchor: "middle",
        font_family: "Arial, sans-serif"
      }
      svg_element("text", {x: x, y: y}.merge(default_attrs).merge(attributes)) { content }
    end

    def svg_container(width:, height:, &block)
      svg_element("svg", {
        width: width,
        height: height,
        xmlns: "http://www.w3.org/2000/svg"
      }, &block)
    end

    def kebab_case(key)
      key.to_s.tr("_", "-")
    end

    def cell_border(x, y, color, cell_size:, border_width:, darker_color_method:)
      return "" unless border_width > 0

      # Inset the border rect by half the stroke width so stroke stays inside
      inset = border_width / 2.0
      border_x = x + inset
      border_y = y + inset
      border_size = cell_size - border_width
      border_color = darker_color_method.call(color)

      svg_rect(
        x: border_x, y: border_y,
        width: border_size, height: border_size,
        fill: "none", stroke: border_color, stroke_width: border_width
      )
    end

    def score_to_color(score, colors:)
      return colors.first if score == 0

      max_color_index = colors.length - 1
      color_index = 1 + (score - 1) % max_color_index
      colors[color_index]
    end

    def darker_color(hex_color, factor: 0.7)
      hex = hex_color.delete("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)

      r = (r * factor).to_i
      g = (g * factor).to_i
      b = (b * factor).to_i

      "#%02x%02x%02x" % [r, g, b]
    end


    def make_color_inactive(hex_color)
      hex = hex_color.delete("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)

      # Blend with light gray to make it appear duller/inactive
      gray = 230
      mix_ratio = 0.6 # 60% original color, 40% gray

      r = blend_color_component(r, gray, mix_ratio)
      g = blend_color_component(g, gray, mix_ratio)
      b = blend_color_component(b, gray, mix_ratio)

      "#%02x%02x%02x" % [r, g, b]
    end

    def blend_color_component(original, target, mix_ratio)
      (original * mix_ratio + target * (1 - mix_ratio)).to_i
    end
  end
end
