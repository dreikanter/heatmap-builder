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

    def svg_rect(x:, y:, width:, height:, rx: nil, **attributes)
      attrs = {x: x, y: y, width: width, height: height}
      attrs[:rx] = rx if rx && rx > 0
      svg_element("rect", attrs.merge(attributes))
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

    def cell_border(x, y, color, cell_size:, border_width:, corner_radius:, darker_color_method:)
      return "" unless border_width > 0

      inset = border_width / 2.0
      border_x = x + inset
      border_y = y + inset
      border_size = cell_size - border_width
      border_color = darker_color_method.call(color)
      border_radius = corner_radius > 0 ? [corner_radius - inset, 0].max : 0

      svg_rect(
        x: border_x, y: border_y,
        width: border_size, height: border_size,
        rx: border_radius,
        fill: "none", stroke: border_color, stroke_width: border_width
      )
    end
  end
end
