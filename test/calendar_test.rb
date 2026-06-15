require "test_helper"

describe HeatmapBuilder::Calendar do
  def scores
    {
      "2024-01-01" => 1,
      "2024-01-02" => 2,
      "2024-01-03" => 0,
      "2024-01-07" => 3
    }
  end

  def builder
    HeatmapBuilder::Calendar.new(scores: scores)
  end

  it "should build SVG with default options" do
    svg = builder.build
    assert_matches_snapshot(svg, "calendar_basic.svg")
  end

  it "should use Monday as start of week when specified" do
    builder = HeatmapBuilder::Calendar.new(scores: scores, start_of_week: :monday)
    assert_matches_snapshot(builder.build, "start_with_monday.svg")
  end

  it "should use Sunday as start of week when specified" do
    builder = HeatmapBuilder::Calendar.new(scores: scores, start_of_week: :sunday)
    assert_matches_snapshot(builder.build, "start_with_sunday.svg")
  end

  it "should display month labels when enabled" do
    builder = HeatmapBuilder::Calendar.new(scores: scores, show_month_labels: true)
    assert_matches_snapshot(builder.build, "with_months.svg")
  end

  it "should display day labels when enabled" do
    builder = HeatmapBuilder::Calendar.new(scores: scores, show_day_labels: true)
    assert_matches_snapshot(builder.build, "with_dows.svg")
  end

  it "should use custom colors when provided" do
    colors = %w[#ffffff #ff0000 #00ff00]
    builder = HeatmapBuilder::Calendar.new(scores: scores, colors: colors)
    assert_matches_snapshot(builder.build, "custom_colors.svg")
  end

  it "should raise errors for invalid inputs" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::Calendar.new(scores: "invalid")
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::Calendar.new(scores: scores, cell_size: 0)
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::Calendar.new(scores: scores, colors: [])
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::Calendar.new(scores: scores, start_of_week: :invalid)
    end

    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::Calendar.new(scores: scores, border_lightness_factor: 0)
    end
  end

  it "should use border_lightness_factor to derive the border color" do
    light = HeatmapBuilder::Calendar.new(scores: scores, border_lightness_factor: 0.9).build
    dark = HeatmapBuilder::Calendar.new(scores: scores, border_lightness_factor: 0.5).build

    refute_equal light, dark
  end

  it "should omit the border when border_lightness_factor is 1" do
    svg = HeatmapBuilder::Calendar.new(scores: scores, border_lightness_factor: 1).build

    refute_includes svg, "stroke="
  end

  it "should accept Date objects as keys" do
    date_scores = {
      Date.new(2024, 1, 1) => 1,
      Date.new(2024, 1, 2) => 2
    }

    assert HeatmapBuilder::Calendar.new(scores: date_scores)
  end

  it "should handle empty scores hash" do
    builder = HeatmapBuilder::Calendar.new(scores: {})
    assert builder.build
  end

  it "should apply corner_radius to cells" do
    builder = HeatmapBuilder::Calendar.new(scores: scores, corner_radius: 2)
    svg = builder.build

    assert_includes svg, 'rx="2"'
  end

  it "should normalize corner_radius to maximum allowed value" do
    builder = HeatmapBuilder::Calendar.new(scores: scores, cell_size: 12, corner_radius: 100)
    svg = builder.build

    assert_includes svg, 'rx="6"'
  end

  # Tests for value-based calendar heatmap generation
  it "should convert values to scores using default linear formula" do
    date_values = {
      Date.new(2024, 1, 1) => 0,
      Date.new(2024, 1, 2) => 50,
      Date.new(2024, 1, 3) => 100
    }

    builder = HeatmapBuilder::Calendar.new(
      values: date_values,
      value_min: 0,
      value_max: 100
    )
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_default_formula.svg")
  end

  it "should handle missing dates by normalizing to minimum" do
    date_values = {
      Date.new(2024, 1, 1) => 50,
      Date.new(2024, 1, 3) => 100
    }

    builder = HeatmapBuilder::Calendar.new(
      values: date_values,
      value_min: 0,
      value_max: 100
    )
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_missing_dates.svg")
  end

  it "should auto-calculate value_min and value_max from calendar data" do
    date_values = {
      Date.new(2024, 1, 1) => 10,
      Date.new(2024, 1, 2) => 20,
      Date.new(2024, 1, 3) => 30
    }

    builder = HeatmapBuilder::Calendar.new(values: date_values)
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_auto_boundaries.svg")
  end

  it "should reserve score 0 for empty cells and bucket a small value above zero" do
    builder = HeatmapBuilder::Calendar.new(
      values: {Date.new(2024, 1, 1) => 1, Date.new(2024, 1, 2) => 1000},
      value_min: 0,
      value_max: 1000
    )

    # Zero and missing values collapse to the reserved empty bucket...
    assert_equal 0, builder.send(:convert_value_to_score, 0)
    assert_equal 0, builder.send(:convert_value_to_score, nil)

    # ...while a tiny value next to a large maximum still lands in the first
    # active bucket rather than being rounded down into the empty one.
    assert_equal 1, builder.send(:convert_value_to_score, 1)
    assert_equal 4, builder.send(:convert_value_to_score, 1000)
  end

  it "should accept custom value_to_score callable for calendar" do
    # Custom formula: always return score 2
    custom_fn = ->(value:, date:, min:, max:, max_score:) { 2 }

    date_values = {
      Date.new(2024, 1, 1) => 10,
      Date.new(2024, 1, 2) => 20
    }

    builder = HeatmapBuilder::Calendar.new(
      values: date_values,
      value_to_score: custom_fn
    )
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_custom_formula.svg")
  end

  it "should pass date parameter to custom value_to_score" do
    received_params = []
    custom_fn = ->(value:, date:, min:, max:, max_score:) {
      received_params << {value: value, date: date, min: min, max: max, max_score: max_score}
      0
    }

    date1 = Date.new(2024, 1, 1)
    date2 = Date.new(2024, 1, 2)
    date_values = {
      date1 => 10,
      date2 => 20
    }

    builder = HeatmapBuilder::Calendar.new(
      values: date_values,
      value_min: 0,
      value_max: 100,
      value_to_score: custom_fn
    )
    builder.build

    assert_equal 2, received_params.length
    assert_equal 10, received_params[0][:value]
    assert_equal date1, received_params[0][:date]
    assert_equal 0, received_params[0][:min]
    assert_equal 100, received_params[0][:max]
  end

  it "should handle string date keys in values hash" do
    date_values = {
      "2024-01-01" => 10,
      "2024-01-02" => 20
    }

    builder = HeatmapBuilder::Calendar.new(values: date_values)
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_string_dates.svg")
  end

  it "should split weeks at month boundaries when month_spacing is positive" do
    # Jan 25 - Feb 5, 2024. Week of Jan 29-Feb 4 spans month boundary.
    # With monday start, split_at=3: Mon-Wed (Jan 29-31) in one column, Thu-Sun (Feb 1-4) in next.
    month_scores = {}
    (Date.new(2024, 1, 25)..Date.new(2024, 2, 5)).each { |d| month_scores[d] = 1 }

    builder = HeatmapBuilder::Calendar.new(
      scores: month_scores,
      month_spacing: 5,
      start_of_week: :monday
    )
    assert_matches_snapshot(builder.build, "month_spacing_split.svg")
  end

  it "should split weeks with outside cells visible" do
    month_scores = {}
    (Date.new(2024, 1, 25)..Date.new(2024, 2, 5)).each { |d| month_scores[d] = 1 }

    builder = HeatmapBuilder::Calendar.new(
      scores: month_scores,
      month_spacing: 5,
      start_of_week: :monday,
      show_outside_cells: true
    )
    assert_matches_snapshot(builder.build, "month_spacing_split_outside.svg")
  end

  it "should not split weeks when month_spacing is zero" do
    month_scores = {}
    (Date.new(2024, 1, 25)..Date.new(2024, 2, 5)).each { |d| month_scores[d] = 1 }

    builder = HeatmapBuilder::Calendar.new(
      scores: month_scores,
      month_spacing: 0,
      start_of_week: :monday
    )
    assert_matches_snapshot(builder.build, "no_month_spacing_split.svg")
  end

  it "should position month labels above first full column, not split column" do
    # Dec 1, 2024 is Sunday. The split Column B has only 1 cell.
    # The "Dec" label should be on the first full December column (Dec 2-8), not Dec 1.
    month_scores = {}
    (Date.new(2024, 11, 1)..Date.new(2025, 1, 31)).each { |d| month_scores[d] = 1 }

    builder = HeatmapBuilder::Calendar.new(
      scores: month_scores,
      month_spacing: 10,
      start_of_week: :monday
    )
    assert_matches_snapshot(builder.build, "month_spacing_label_on_full_column.svg")
  end

  it "should label the first full week regardless of month_spacing" do
    # Dec 29 2025 - Jan 4 2026 is a single Mon-Sun week straddling the year.
    # The "Jan" label belongs on the first full January week (Jan 5-11) whether
    # or not month_spacing splits the straddling week into separate columns.
    month_scores = {}
    (Date.new(2025, 12, 15)..Date.new(2026, 1, 31)).each { |d| month_scores[d] = 1 }

    [0, 8].each do |spacing|
      builder = HeatmapBuilder::Calendar.new(
        scores: month_scores,
        month_spacing: spacing,
        start_of_week: :monday
      )

      jan_label = builder.send(:column_layout).find do |col|
        col[:first_of_month] && col[:month_date].month == 1
      end

      assert jan_label, "expected a January label with month_spacing=#{spacing}"
      jan_days = jan_label[:days].map(&:first)
      assert_equal 7, jan_days.size, "label column should be a full week (spacing=#{spacing})"
      assert_equal Date.new(2026, 1, 5), jan_days.first, "spacing=#{spacing}"
    end
  end

  it "should not label a month whose only visible week is incomplete" do
    # Jan 28 2026 is a Wednesday, so the interval's leading week (Jan 26-Feb 1,
    # Monday start) is incomplete and is January's only visible week. Without a
    # full week, January must not be labeled — otherwise its label would crowd
    # into February's adjacent column. February's first full week (Feb 2-8)
    # still carries its label.
    scores = {}
    (Date.new(2026, 1, 28)..Date.new(2026, 3, 15)).each { |d| scores[d] = 1 }

    [0, 8].each do |spacing|
      builder = HeatmapBuilder::Calendar.new(
        scores: scores,
        month_spacing: spacing,
        start_of_week: :monday
      )

      labeled = builder.send(:column_layout).select { |col| col[:first_of_month] }
      labeled_months = labeled.map { |col| col[:month_date].month }

      refute_includes labeled_months, 1, "January sliver should be unlabeled (spacing=#{spacing})"

      feb_label = labeled.find { |col| col[:month_date].month == 2 }
      assert feb_label, "expected a February label with month_spacing=#{spacing}"
      assert_equal Date.new(2026, 2, 2), feb_label[:days].map(&:first).first, "spacing=#{spacing}"
    end
  end

  describe "tooltip" do
    def tooltip_scores
      {
        Date.new(2024, 1, 1) => 1,
        Date.new(2024, 1, 2) => 3
      }
    end

    it "should not include tooltip markup when tooltip is not configured" do
      svg = HeatmapBuilder::Calendar.new(scores: tooltip_scores).build
      refute_includes svg, "<title>"
      refute_includes svg, "<g "
    end

    it "should wrap active cells in <g> with <title> when tooltip is configured" do
      builder = HeatmapBuilder::Calendar.new(
        scores: tooltip_scores,
        tooltip: ->(date:, score:, value: nil) { "#{date}: #{score}" }
      )
      svg = builder.build
      assert_includes svg, "<title>2024-01-01: 1</title>"
      assert_includes svg, "<title>2024-01-02: 3</title>"
      assert_includes svg, "<g "
    end

    it "should emit default data-tooltip attribute" do
      builder = HeatmapBuilder::Calendar.new(
        scores: tooltip_scores,
        tooltip: ->(date:, score:, value: nil) { "#{date}: #{score}" }
      )
      svg = builder.build
      assert_includes svg, 'data-tooltip="2024-01-01: 1"'
      assert_includes svg, 'data-tooltip="2024-01-02: 3"'
    end

    it "should use custom tooltip_attribute when specified" do
      builder = HeatmapBuilder::Calendar.new(
        scores: tooltip_scores,
        tooltip: ->(date:, score:, value: nil) { "#{date}: #{score}" },
        tooltip_attribute: "data-tippy-content"
      )
      svg = builder.build
      assert_includes svg, 'data-tippy-content="2024-01-01: 1"'
      refute_includes svg, "data-tooltip="
    end

    it "should omit data attribute when tooltip_attribute is nil" do
      builder = HeatmapBuilder::Calendar.new(
        scores: tooltip_scores,
        tooltip: ->(date:, score:, value: nil) { "#{date}: #{score}" },
        tooltip_attribute: nil
      )
      svg = builder.build
      assert_includes svg, "<title>2024-01-01: 1</title>"
      refute_includes svg, "data-tooltip"
    end

    it "should pass raw value to tooltip proc when values mode is used" do
      received = {}
      builder = HeatmapBuilder::Calendar.new(
        values: {Date.new(2024, 1, 1) => 42, Date.new(2024, 1, 2) => 99},
        tooltip: ->(date:, score:, value: nil) {
          received[date] = value
          "#{date}: #{value}"
        }
      )
      builder.build
      assert_equal 42, received[Date.new(2024, 1, 1)]
      assert_equal 99, received[Date.new(2024, 1, 2)]
    end

    it "should pass nil value to tooltip proc when scores mode is used" do
      received_value = :sentinel
      builder = HeatmapBuilder::Calendar.new(
        scores: tooltip_scores,
        tooltip: ->(date:, score:, value: nil) {
          received_value = value if date == Date.new(2024, 1, 1)
          date.to_s
        }
      )
      builder.build
      assert_nil received_value
    end

    it "should not add tooltip to outside cells" do
      builder = HeatmapBuilder::Calendar.new(
        scores: {Date.new(2024, 1, 3) => 2},
        show_outside_cells: true,
        tooltip: ->(date:, score:, value: nil) { date.to_s }
      )
      svg = builder.build
      assert_includes svg, "<title>2024-01-03</title>"
      assert_equal 1, svg.scan("<title>").length
    end

    it "should escape special characters in tooltip text" do
      builder = HeatmapBuilder::Calendar.new(
        scores: {Date.new(2024, 1, 1) => 2},
        tooltip: ->(date:, score:, value: nil) { "Score: <#{score}> & more" }
      )
      svg = builder.build
      assert_includes svg, "Score: &lt;2&gt; &amp; more"
    end

    it "should raise error when tooltip is not callable" do
      assert_raises(HeatmapBuilder::Error) do
        HeatmapBuilder::Calendar.new(scores: tooltip_scores, tooltip: "not callable")
      end
    end

    it "should match tooltip snapshot" do
      builder = HeatmapBuilder::Calendar.new(
        scores: tooltip_scores,
        tooltip: ->(date:, score:, value: nil) { "#{date}: #{score} contributions" }
      )
      assert_matches_snapshot(builder.build, "calendar_with_tooltip.svg")
    end
  end

  it "should raise error if both scores and values provided for calendar" do
    assert_raises(HeatmapBuilder::Error) do
      HeatmapBuilder::Calendar.new(
        scores: {Date.new(2024, 1, 1) => 1},
        values: {Date.new(2024, 1, 1) => 10}
      )
    end
  end

  it "should handle empty values hash for calendar" do
    # Use a fixed date to avoid snapshot changing daily
    date_values = {
      Date.new(2024, 1, 1) => 0
    }

    builder = HeatmapBuilder::Calendar.new(values: date_values)
    svg = builder.build

    assert_matches_snapshot(svg, "calendar_values_empty.svg")
  end
end
