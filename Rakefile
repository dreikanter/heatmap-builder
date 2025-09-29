require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

begin
  require "standard/rake"
rescue LoadError
  # standard is not available
end

desc "Update test snapshots"
task :update_snapshots do
  require "fileutils"
  snapshots_dir = File.expand_path("test/snapshots", __dir__)

  if Dir.exist?(snapshots_dir)
    puts "Removing existing snapshots..."
    FileUtils.rm_rf(Dir["#{snapshots_dir}/*"])
  end

  puts "Regenerating snapshots..."
  ENV['UPDATE_SNAPSHOTS'] = '1'
  Rake::Task[:test].invoke
end

task default: [:standard, :test]
