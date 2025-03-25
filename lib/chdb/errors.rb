# frozen_string_literal: true

module ChDB
  # Represents a base exception class for the ChDB module.
  # This class inherits from StandardError and provides a common
  # structure for other ChDB-specific exceptions.
  class Exception < ::StandardError
    # A convenience for accessing the error code for this exception.
    attr_reader :code

    # If the error is associated with a SQL query, this is the query
    attr_reader :sql
  end

  class SQLException < Exception; end

  class InternalException < Exception; end

  class DirectoryNotFoundException < ChDB::Exception; end

  class InvalidArgumentException < ChDB::Exception; end
end
