# frozen_string_literal: true

require 'cgi'
require 'fileutils'
require 'tempfile'
require 'chdb/constants'
require 'chdb/errors'

module ChDB
  # Represents the data path configuration for ChDB.
  # This class is responsible for initializing and managing the data path
  # including parsing URIs, handling query parameters, and ensuring directory existence.
  class DataPath
    attr_reader :dir_path, :is_tmp, :query_params, :mode

    def initialize(uri, options)
      initialize_instance_variables
      path = parse_uri(uri)
      merge_options(options)
      check_params
      directory_path(path)
    end

    def generate_arguments # rubocop:disable Metrics/MethodLength
      args = ['clickhouse', "--path=#{@dir_path}"]
      excluded_keys = %w[results_as_hash readonly readwrite flags]

      @query_params.each do |key, value|
        next if excluded_keys.include?(key)

        case key.to_s
        when 'udf_path'
          udf_value = value.to_s
          args += ['--', "--user_scripts_path=#{udf_value}",
                   "--user_defined_executable_functions_config=#{udf_value}/*.xml"]
          next
        when '--'
          args << '--'
          next
        end

        key_str = key.to_s
        args << if value.nil?
                  "--#{key_str}"
                else
                  "--#{key_str}=#{value}"
                end
      end

      args << '--readonly=1' if @mode.anybits?(Constants::Open::READONLY)

      args
    end

    def close
      FileUtils.remove_entry(@dir_path, true) if @is_tmp && Dir.exist?(@dir_path)
    end

    private

    def initialize_instance_variables
      @dir_path = nil
      @is_tmp = false
      @query_params = {}
      @mode = 0
    end

    def parse_uri(uri)
      path, query_str = uri.split('?', 2) unless uri.nil?
      @query_params = CGI.parse(query_str.to_s).transform_values(&:last) unless query_str.nil?
      remove_file_prefix(path)
    end

    def merge_options(options)
      @query_params = @query_params.merge(options.transform_keys(&:to_s))
    end

    def directory_path(path)
      if path.nil? || path.empty? || path == ':memory:'
        @is_tmp = true
        @dir_path = Dir.mktmpdir('chdb_')
      else
        @dir_path = File.expand_path(path)
        ensure_directory_exists
      end
    end

    def ensure_directory_exists
      return if Dir.exist?(@dir_path)

      raise DirectoryNotFoundException, "Directory #{@dir_path} required" if @mode.nobits?(Constants::Open::CREATE)

      FileUtils.mkdir_p(@dir_path, mode: 0o755)
    end

    def check_params # rubocop:disable Metrics/MethodLength
      @mode = Constants::Open::READWRITE | Constants::Open::CREATE
      @mode = Constants::Open::READONLY if @query_params['readonly']

      if @query_params['readwrite']
        raise InvalidArgumentException, 'conflicting options: readonly and readwrite' if @query_params['readonly']

        @mode = Constants::Open::READWRITE
      end

      return unless @query_params['flags']
      if @query_params['readonly'] || @query_params['readwrite']
        raise InvalidArgumentException, 'conflicting options: flags with readonly and/or readwrite'
      end

      @mode = @query_params['flags']
    end

    def remove_file_prefix(str)
      str.sub(/\Afile:/, '')
    end
  end
end
