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
