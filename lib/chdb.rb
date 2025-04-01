# frozen_string_literal: true

module ChDB
  def self.lib_file_path
    @lib_file_path ||= File.expand_path(__FILE__)
  end
end

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "chdb/#{Regexp.last_match(1)}/chdb_native"
rescue LoadError
  require 'chdb/chdb_native'
end

require 'chdb/database'
require 'chdb/version'
require 'chdb/version_info'
