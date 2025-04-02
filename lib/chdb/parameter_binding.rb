# frozen_string_literal: true

module ChDB
  # Documentation for the ParameterBinding module
  # This module provides methods for binding parameters in a database query context.
  module ParameterBinding
    def bind_param(index, value)
      @bind_vars[index - 1] = value
    end

    def bind_params(*bind_vars)
      index = 1
      bind_vars.flatten.each do |var|
        bind_param index, var
        index += 1
      end
    end
  end
end
