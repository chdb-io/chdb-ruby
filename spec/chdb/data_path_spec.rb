# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe ChDB::DataPath do
  let(:test_db_path) { File.join(__dir__, 'testdb') }

  before do
    FileUtils.rm_rf(test_db_path) if Dir.exist?(test_db_path)
  end

  after { FileUtils.remove_entry(test_db_path) if Dir.exist?(test_db_path) }

  describe '#initialize' do
    it 'parses URI with memory path' do
      path = described_class.new('file::memory:?key1=value1', {})
      # puts path.dir_path
      expect(path.dir_path).to match(/chdb_/)
      expect(path.is_tmp).to be true
      expect(path.query_params.transform_keys(&:to_s)).to include('key1' => 'value1')
      path.close()
    end

    it 'parses URI with file path' do
      path = described_class.new("file:#{test_db_path}?key1=value1", {})
      expect(path.dir_path).to eq(test_db_path)
      expect(path.query_params.transform_keys(&:to_s)).to include('key1' => 'value1')
    end

    it 'parses URI with query parameters' do
      path = described_class.new("file:#{test_db_path}?key1=value1", {})
      path = described_class.new("#{test_db_path}?key1=value1&readonly=1", {})
      expect(path.query_params).to include('key1' => 'value1', 'readonly' => '1')
    end

    it 'merges options with URI params1' do
      path = described_class.new('test?key1=value1', { results_as_hash: true })
      expect(path.query_params.transform_keys(&:to_s)).to include('key1' => 'value1', 'results_as_hash' => true)
    end

    it 'merges options with URI params2' do
      path = described_class.new('test?key1=value1&results_as_hash=true', { results_as_hash: false })
      expect(path.query_params.transform_keys(&:to_s)).to include('key1' => 'value1', 'results_as_hash' => false)
    end
  end

  describe '#generate_arguments' do
    it 'filters special parameters' do
      path = described_class.new(':memory:', results_as_hash: true, flags: 3)
      args = path.generate_arguments
      expect(args).not_to include(a_string_matching(/results_as_hash/))
      expect(args).not_to include(a_string_matching(/flags/))
      path.close()
    end

    it 'generates UDF arguments' do
      path = described_class.new('testdb', { udf_path: '/custom/udf' })
      args = path.generate_arguments
      expect(args).to include('--user_scripts_path=/custom/udf')
      expect(args).to include('--user_defined_executable_functions_config=/custom/udf/*.xml')
    end

    it 'handles normal parameters' do
      path = described_class.new('testdb', { key1: 'value1' })
      args = path.generate_arguments
      expect(args).to include('--key1=value1')
    end
  end

  describe 'directory handling' do
    it 'creates temp dir for :memory:' do
      path = described_class.new(':memory:', {})
      expect(path.dir_path).to match(/chdb_/)
      expect(path.is_tmp).to be true
      path.close()
    end

    it 'uses existing directory' do
      FileUtils.mkdir_p(test_db_path, mode: 0o755) unless Dir.exist?(test_db_path)
      path = described_class.new(test_db_path, { flags: 2 })
      expect(path.dir_path).to eq(File.expand_path(test_db_path))
      expect(path.is_tmp).to be false
      FileUtils.remove_entry(path.dir_path)
    end

    it 'raises error when directory not exist without CREATE flag' do
      FileUtils.rm_rf(test_db_path) if Dir.exist?(test_db_path)

      expect do
        described_class.new(test_db_path, { flags: 2 })
      end.to raise_error(ChDB::DirectoryNotFoundException)

      FileUtils.rm_rf(test_db_path) if Dir.exist?(test_db_path)
    end
  end

  describe 'mode flags' do
    it 'sets readonly mode' do
      path = described_class.new("file:test?key1=value1", {})
      path = described_class.new('test', { readonly: true })
      expect(path.mode & ChDB::Constants::Open::READONLY).not_to be_zero
    end

    it 'raises error on conflicting flags' do
      expect do
        described_class.new('test', { readonly: true, flags: ChDB::Constants::Open::READWRITE })
      end.to raise_error(ChDB::InvalidArgumentException)
    end
  end
end
