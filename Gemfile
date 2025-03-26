# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :test do
  gem 'rake-compiler', '1.2.9'
  gem 'rake-compiler-dock', '1.9.1'
  gem 'rspec', '3.12.0'
  gem 'ruby_memcheck', '3.0.1' if Gem::Platform.local.os == 'linux'
end

group :development do
  gem 'rdoc', '6.12.0'
  gem 'rubocop', '1.74.0', require: false
end
