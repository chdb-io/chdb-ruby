# frozen_string_literal: true

module ChDB
  # This module provides functionality for processing SQL queries,
  # including binding variables and escaping values.
  module SQLProcessor
    def process_sql
      escaped_values = @bind_vars.map { |v| escape(v) }
      sql = @sql.dup
      sql.gsub(/(?<!\\)\?/) { escaped_values.shift or "?" }
    end

    def escape(value)
      case value
      when String then "'#{value.gsub("'", "''")}'"
      when NilClass then "NULL"
      when TrueClass then "1"
      when FalseClass then "0"
      else value.to_s
      end
    end
  end
end
