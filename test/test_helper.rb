if ENV["CI"].nil? || ENV["CI"] == "false"
  require "simplecov"

  SimpleCov.start do
    add_filter "/test/"
    minimum_coverage 90
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "heatmap-builder"

require "minitest/autorun"
require "minitest/spec"
require "fileutils"

def assert_matches_snapshot(actual_content, snapshot_name)
  snapshot_path = File.join(__dir__, "snapshots", snapshot_name)

  if ENV["UPDATE_SNAPSHOTS"]
    FileUtils.mkdir_p(File.dirname(snapshot_path))
    File.write(snapshot_path, actual_content)
    skip "Generated snapshot: #{snapshot_name}"
    return
  end

  if File.exist?(snapshot_path)
    expected = File.read(snapshot_path)
    if expected != actual_content
      # Provide concise diff message without dumping full SVG
      expected_size = expected.bytesize
      actual_size = actual_content.bytesize
      expected_preview = expected[0..100].gsub("\n", " ")
      actual_preview = actual_content[0..100].gsub("\n", " ")

      message = "Snapshot mismatch for #{snapshot_name}\n"
      message += "Expected size: #{expected_size} bytes, Actual size: #{actual_size} bytes\n"
      message += "Expected preview: #{expected_preview}...\n"
      message += "Actual preview: #{actual_preview}...\n"
      message += "Run with UPDATE_SNAPSHOTS=1 to update snapshots"

      flunk message
    end
  else
    flunk "missing snapshot; run with UPDATE_SNAPSHOTS=1 to regenerate snapshots"
  end
end
