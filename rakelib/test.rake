# frozen_string_literal: true

require 'rspec/core/rake_task'

CHDB_SPEC = Bundler.load_gemspec('chdb.gemspec')

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task test: :spec
