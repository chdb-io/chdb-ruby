# frozen_string_literal: true

require 'chdb/chdb_native'
require 'chdb/data_path'
require 'chdb/statement'

module ChDB
  # Represents a database connection and provides methods to interact with the database.
  class Database # rubocop:disable Metrics/ClassLength
    class << self
      # Without block works exactly as new.
      # With block, like new closes the database at the end, but unlike new
      # returns the result of the block instead of the database instance.
      def open(*args)
        database = new(*args)

        if block_given?
          begin
            yield database
          ensure
            database.close
          end
        else
          database
        end
      end
    end

    # A boolean that indicates whether rows in result sets should be returned
    # as hashes or not. By default, rows are returned as arrays.
    attr_accessor :results_as_hash, :conn

    def initialize(file, options = {}) # rubocop:disable Metrics/MethodLength
      file = file.to_path if file.respond_to? :to_path

      @data_path = DataPath.new(file, options)
      @results_as_hash = @data_path.query_params[:results_as_hash]
      @readonly = @data_path.mode & Constants::Open::READONLY != 0

      argv = @data_path.generate_arguments
      @conn = ChDB::Connection.new(argv.size, argv)
      @closed = false

      return unless block_given?

      begin
        yield self
      ensure
        close
      end
    end

    def close
      return if defined?(@closed) && @closed

      @data_path.close if @data_path.respond_to?(:close)
      @conn.close if @conn.respond_to?(:close)
      @closed = true
    end

    def closed?
      defined?(@closed) && @closed
    end

    def prepare(sql)
      stmt = ChDB::Statement.new(self, sql)
      return stmt unless block_given?

      yield stmt
    end

    def execute(sql, bind_vars = [], &block)
      prepare(sql) do |stmt|
        result = stmt.execute(bind_vars)

        if block
          result.each(&block)
        else
          result.to_a.freeze
        end
      end
    end

    def execute2(sql, *bind_vars, &) # rubocop:disable Metrics/MethodLength
      prepare(sql) do |stmt|
        result = stmt.execute(*bind_vars)
        stmt.parse

        if block_given?
          yield stmt.columns
          result.each(&)
        else
          return result.each_with_object([stmt.columns]) do |row, arr|
                   arr << row
                 end
        end
      end
    end

    def query(sql, bind_vars = [])
      result = prepare(sql).execute(bind_vars)
      if block_given?
        yield result
      else
        result
      end
    end

    def query_with_format(sql, bind_vars = [], format = 'CSV')
      result = prepare(sql).execute_with_format(bind_vars, format)
      if block_given?
        yield result
      else
        result
      end
    end

    def get_first_row(sql, *bind_vars)
      execute(sql, *bind_vars).first
    end

    def get_first_value(sql, *bind_vars)
      query(sql, bind_vars) do |rs|
        if (row = rs.next)
          return @results_as_hash ? row[rs.columns[0]] : row[0]
        end
      end
      nil
    end

    # Returns +true+ if the database has been open in readonly mode
    # A helper to check before performing any operation
    def readonly?
      @readonly
    end

    # Given a statement, return a result set.
    # This is not intended for general consumption
    # :nodoc:
    def build_result_set(stmt)
      if results_as_hash
        HashResultSet.new(self, stmt)
      else
        ResultSet.new(self, stmt)
      end
    end
  end
end
