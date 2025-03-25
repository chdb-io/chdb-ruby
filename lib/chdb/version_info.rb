# frozen_string_literal: true

module ChDB
  # a hash of descriptive metadata about the current version of the chdb gem
  VERSION_INFO = {
    ruby: RUBY_DESCRIPTION,
    gem: {
      version: ChDB::VERSION
    }
  }.freeze
end
