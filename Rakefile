# encoding: UTF-8

require 'rake/testtask'
require 'inch/rake'

task default: [:test, 'doc:suggest']

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end
task spec: :test

Inch::Rake::Suggest.new('doc:suggest') do |suggest|
  suggest.args << '--private'
end
