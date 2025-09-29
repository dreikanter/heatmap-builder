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

  if File.exist?(snapshot_path) && !ENV['UPDATE_SNAPSHOTS']
    expected = File.read(snapshot_path)
    assert_equal expected, actual_content, "Snapshot mismatch for #{snapshot_name}"
  else
    FileUtils.mkdir_p(File.dirname(snapshot_path))
    File.write(snapshot_path, actual_content)
    puts "📸 Snapshot: #{snapshot_name}"
    assert true, "Generated snapshot: #{snapshot_name}"
  end
end

def valid_hex_color
  /^#[0-9a-f]{6}$/
end
