# frozen_string_literal: true

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "ChDB/#{Regexp.last_match(1)}/chdb"
rescue LoadError
  require "ChDB/chdb"
end

require "chdb/database"
require "chdb/version"
require "chdb/version_info"
