# frozen_string_literal: true

require 'csv'
begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "chdb/#{Regexp.last_match(1)}/chdb_native"
rescue LoadError
  require 'chdb/chdb_native'
end
require 'chdb/local_result'
require 'chdb/result_set'
require 'chdb/result_handler'
require 'chdb/parameter_binding'
require 'chdb/sql_processor'

module ChDB
  # Represents a prepared SQL statement in the ChDB database.
  # This class provides methods for executing SQL statements, binding parameters,
  # and iterating over the result set.
  class Statement
    include Enumerable
    include ParameterBinding
    include SQLProcessor
    include ResultHandler

    attr_reader :result, :columns, :parsed_data

    def initialize(db, sql_str)
      validate_inputs(db, sql_str)
      @sql = encode_sql(sql_str)
      @connection = db
      @executed = false
      @parsed = false
      @row_idx = 0
      @bind_vars = []
      @parsed_data = []
      @columns = []
    end

    def execute(*bind_vars)
      reset! if @executed
      @executed = true

      bind_params(*bind_vars) unless bind_vars.empty?

      @processed_sql = process_sql

      results = @connection.build_result_set self
      @result = @connection.conn.query(@processed_sql, 'CSVWithNames')
      @result.output_format = 'CSVWithNames'

      yield results if block_given?
      results
    end

    def execute!(*bind_vars, &block)
      execute(*bind_vars)
      block ? each(&block) : to_a
    end

    def execute_with_format(*bind_vars, format)
      reset! if @executed
      @executed = true

      bind_params(*bind_vars) unless bind_vars.empty?

      @processed_sql = process_sql
      @result = @connection.conn.query(@processed_sql, format)

      yield @result.buf if block_given?
      @result.buf
    end

    def reset!
      @executed = false
      @parsed = false
      @row_idx = 0
      @bind_vars.clear
      @parsed_data.clear
      @columns.clear
      @results = nil
    end

    def step
      parse
      return nil if @row_idx >= @parsed_data.size

      current_row = @parsed_data[@row_idx]
      @row_idx += 1
      current_row
    end

    def parse
      return if @parsed

      if @result&.buf.to_s.empty?
        @columns = []
        @parsed_data = []
      else
        @columns, @parsed_data = ResultHandler.parse_output(@result.buf)
      end

      @parsed = true
      @results = nil
    end

    private

    def validate_inputs(db, sql_str)
      raise ArgumentError, 'SQL statement cannot be nil' if sql_str.nil?
      raise ArgumentError, 'prepare called on a closed database' if db.nil? || db.closed?
    end

    def encode_sql(sql_str)
      if sql_str.encoding == Encoding::UTF_8
        sql_str.dup
      else
        sql_str.encode(Encoding::UTF_8)
      end
    end

    # Returns true if the statement is currently active, meaning it has an
    # open result set.
    def active?
      @executed && !done?
    end

    def each
      loop do
        val = step
        break if val.nil?

        yield val
      end
    end
  end
end
