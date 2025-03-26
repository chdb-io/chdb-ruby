# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"
require "rubocop/rake_task"

# require "bundler"
CHDB_SPEC = Bundler.load_gemspec("chdb.gemspec")

RSpec::Core::RakeTask.new(:spec)

Rake::ExtensionTask.new("chdb") do |ext|
  ext.lib_dir = "lib/chdb"
end

RuboCop::RakeTask.new

task default: %i[spec rubocop]
