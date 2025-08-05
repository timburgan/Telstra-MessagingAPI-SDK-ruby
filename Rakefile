require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # no rspec available
end

desc "Run minitest tests"
task :test do
  require 'minitest'
  test_files = Dir['test/**/*_test.rb']
  test_files.each { |file| load file }
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = ['--autocorrect']
  end
rescue LoadError
  # no rubocop available
end

task default: [:spec, :test]
