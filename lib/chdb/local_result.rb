# frozen_string_literal: true

module ChDB
  # Represents the local result of a ChDB operation.
  class LocalResult
    attr_accessor :output_format

    def to_s
      buf
    end
  end
end
