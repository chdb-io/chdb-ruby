# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChDB::Database do
  let(:test_db_path) { File.join(__dir__, 'testdb') }

  before do
    FileUtils.rm_rf(test_db_path) if Dir.exist?(test_db_path)
  end

  after { FileUtils.remove_entry(test_db_path) if Dir.exist?(test_db_path) }

  def create_test_table(db) # rubocop:disable Metrics/MethodLength
    db.execute('DROP TABLE IF EXISTS test_table')
    db.execute("CREATE TABLE test_table(
                id Int32,
                name String)
                ENGINE = MergeTree()
                ORDER BY id")
 
    {
      1 => "Alice",
      2 => "Bob"
    }.each do |pair|
      db.execute "INSERT INTO test_table VALUES ( ?, ? )", pair
    end

    db.execute("INSERT INTO test_table (id, name)
                VALUES (?, ?)", ["3", "Charlie"])

    db.execute("INSERT INTO test_table (id, name) VALUES
                (4, 'David')")
  end

  describe '#open' do
    it 'auto-closes database with block' do
      db = nil
      ChDB::Database.open(test_db_path) do |database|
        db = database
        expect(db).to be_a(ChDB::Database)
        expect(db.closed?).to be false
      end
      expect(db.closed?).to be true
    end
  end

  describe '#execute' do
    it 'returns query results with simple query' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        result = db.execute('SELECT 1 AS value')
        expect(result).to eq([{ 'value' => '1' }])
      end
    end

    it 'raises error when closed' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      db.close
      expect { db.execute('SELECT 1') }.to raise_error(ArgumentError, /closed database/)
    end

    it 'create table, insert rows, and returns query results' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        create_test_table(db)
        result = db.execute('SELECT * FROM test_table ORDER BY id')
        expect(result.to_a).to eq([{ 'id' => '1', 'name' => 'Alice' }, { 'id' => '2', 'name' => 'Bob' },
                                   { 'id' => '3', 'name' => 'Charlie' }, { 'id' => '4', 'name' => 'David' }])
      end
    end

    it 'yields rows with block' do
      collected = []
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      db.execute('SELECT * FROM test_table ORDER BY id') do |row|
        collected << row
      end
      expect(collected).to eq([{ 'id' => '1', 'name' => 'Alice' }, { 'id' => '2', 'name' => 'Bob' },
                               { 'id' => '3', 'name' => 'Charlie' }, { 'id' => '4', 'name' => 'David' }])
      db.close
    end

    it 'handles positional parameters' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      result = db.execute('SELECT ? AS num, ? AS str', [42, 'hello'])
      expect(result).to eq([{ 'num' => '42', 'str' => 'hello' }])
      db.close
    end

    it 'query with results_as_hash false' do
      db = ChDB::Database.new(test_db_path, results_as_hash: false)
      create_test_table(db)
      result = db.execute('SELECT * FROM test_table ORDER BY id')
      expect(result).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      db.close
    end
  end

  describe '#execute2' do
    it 'returns query results with simple query' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        result = db.execute2('SELECT 1 AS value')
        expect(result).to eq([['value'], { 'value' => '1' }])
      end
    end

    it 'raises error when closed' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      db.close
      expect { db.execute2('SELECT 1') }.to raise_error(ArgumentError, /closed database/)
    end

    it 'create table, insert rows, and returns query results' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        create_test_table(db)
        result = db.execute2('SELECT * FROM test_table ORDER BY id')
        expect(result.to_a).to eq([%w[id name], { 'id' => '1', 'name' => 'Alice' }, { 'id' => '2', 'name' => 'Bob' },
                                   { 'id' => '3', 'name' => 'Charlie' }, { 'id' => '4', 'name' => 'David' }])
      end
    end

    it 'yields rows with block' do
      collected = []
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      db.execute2('SELECT * FROM test_table ORDER BY id') do |row|
        collected << row
      end
      expect(collected).to eq([%w[id name], { 'id' => '1', 'name' => 'Alice' }, { 'id' => '2', 'name' => 'Bob' },
                               { 'id' => '3', 'name' => 'Charlie' }, { 'id' => '4', 'name' => 'David' }])
      db.close
    end

    it 'handles positional parameters' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      result = db.execute2('SELECT ? AS num, ? AS str', [42, 'hello'])
      expect(result).to eq([%w[num str], { 'num' => '42', 'str' => 'hello' }])
      db.close
    end

    it 'query with results_as_hash false' do
      db = ChDB::Database.new(test_db_path, results_as_hash: false)
      create_test_table(db)
      result = db.execute2('SELECT * FROM test_table ORDER BY id')
      expect(result).to eq([%w[id name], %w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      db.close
    end
  end

  describe '#query' do
    it 'query' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.query('SELECT * FROM test_table ORDER BY id')
      expect(result.to_a).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      db.close
    end
  end

  describe '#query_with_format' do
    it 'query with format' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.query_with_format('SELECT * FROM test_table ORDER BY id', [], 'CSV')
      expect(result).to eq("1,\"Alice\"\n2,\"Bob\"\n3,\"Charlie\"\n4,\"David\"\n")
      db.close
    end
  end

  describe '#get_first_row' do
    it 'get first row' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.get_first_row('SELECT * FROM test_table ORDER BY id')
      expect(result).to eq(%w[1 Alice])
      db.close
    end

    it 'get first row with hash' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      result = db.get_first_row('SELECT * FROM test_table ORDER BY id')
      expect(result).to eq({ 'id' => '1', 'name' => 'Alice' })
      db.close
    end
  end

  describe '#get_first_value' do
    it 'get first value' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.get_first_value('SELECT * FROM test_table ORDER BY id')
      expect(result).to eq('1')
      db.close
    end

    it 'get first value with hash' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      result = db.get_first_value('SELECT * FROM test_table ORDER BY id')
      expect(result).to eq('1')
      db.close
    end
  end

  describe '#prepare' do
    it 'creates reusable statement' do
      ChDB::Database.open(test_db_path) do |db|
        stmt = db.prepare('SELECT ? AS value')
        result = stmt.execute(42)
        expect(result.to_a).to eq([['42']])
      end
    end
  end
end
