require 'rake/testtask'

task :run do
  ruby "lib/blog_to_evernote.rb"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/*_test.rb"
end

task default: %w[test]
