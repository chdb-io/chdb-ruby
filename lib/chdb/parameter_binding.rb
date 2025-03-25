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
        if var.is_a?(Hash)
          # TODO: Hash-style parameter binding not yet implemented
          # Currently using positional parameters instead of named parameters
          var.each { |key, val| bind_param key, val }
        else
          bind_param index, var
          index += 1
        end
      end
    end
  end
end
