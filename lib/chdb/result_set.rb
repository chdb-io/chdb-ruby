# frozen_string_literal: true

module ChDB
  # The ResultSet object encapsulates the enumerability of a query's output.
  # It is a simple cursor over the data that the query returns. It will
  # very rarely (if ever) be instantiated directly. Instead, clients should
  # obtain a ResultSet instance via Statement#execute.
  class ResultSet
    include Enumerable

    # Create a new ResultSet attached to the given database, using the
    # given sql text.
    def initialize(db, stmt)
      @db = db
      @stmt = stmt
    end

    def eof?
      @stmt.done?
    end

    def next
      @stmt.step
    end

    def each
      while (node = self.next)
        yield node
      end
    end

    # Provides an internal iterator over the rows of the result set where
    # each row is yielded as a hash.
    def each_hash
      while (node = next_hash)
        yield node
      end
    end

    # Returns the names of the columns returned by this result set.
    def columns
      @stmt.columns
    end

    # Return the next row as a hash
    def next_hash
      row = @stmt.step
      return nil unless row

      @stmt.columns.zip(row).to_h
    end
  end

  class HashResultSet < ResultSet # :nodoc:
    alias next next_hash
  end

  class StreamingResultSet
    include Enumerable

    def initialize(db, streaming_result)
      @db = db
      @streaming_result = streaming_result
      @done = false
    end

    def eof?
      @done
    end

    def next
      return nil if @done

      result = @db.conn.fetch_streaming_result(@streaming_result)

      if result.nil? || result.rows_read.zero?
        @done = true
        nil
      else
        result
      end
    end

    def each
      while (node = self.next)
        yield node
      end
    end

    def cancel
      return nil if @done

      @db.conn.cancel_streaming_query(@streaming_result)
      @done = true
    end
  end
end
