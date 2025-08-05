require "bundler/gem_tasks"

begin
  require 'minitest/test_task'

  Minitest::TestTask.create(:test) do |t|
    t.test_globs = ["test/**/*_test.rb"]
  end
  
  task default: :test
rescue LoadError
  # no minitest available
end
