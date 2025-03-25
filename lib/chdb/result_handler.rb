# frozen_string_literal: true

module ChDB
  # This module provides a set of methods for handling the results of a ChDB query.
  # It parses the output content into a CSV table and provides methods to iterate over the rows.
  module ResultHandler
    module_function

    def parse_output(output_content)
      csv_table = CSV.parse(output_content, headers: true)
      [csv_table.headers, csv_table.map(&:fields)]
    end

    def step
      return nil if @row_idx >= @parsed_data.size

      current_row = @parsed_data[@row_idx]
      @row_idx += 1
      current_row
    end

    public

    def done?
      @row_idx >= @parsed_data.size
    end
  end
end
