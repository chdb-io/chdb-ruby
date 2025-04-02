# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChDB::Database do
  let(:test_db_path) { File.join(__dir__, 'testdb') }
  let(:test_db_path2) { File.join(__dir__, 'testdb2') }

  # before do
  #   FileUtils.rm_rf(test_db_path) if Dir.exist?(test_db_path)
  #   FileUtils.rm_rf(test_db_path2) if Dir.exist?(test_db_path2)
  # end

  # after do 
  #   FileUtils.remove_entry(test_db_path) if Dir.exist?(test_db_path) 
  #   FileUtils.remove_entry(test_db_path2) if Dir.exist?(test_db_path2)
  # end

  def create_empty_table(db) 
    db.execute('CREATE DATABASE IF NOT EXISTS test')
    db.execute('DROP TABLE IF EXISTS test.test_table')
    db.execute("CREATE TABLE test.test_table(
                id Int32,
                name String)
                ENGINE = MergeTree()
                ORDER BY id")
  end

  def create_test_table(db) 
    create_empty_table(db) 
 
    {
      1 => "Alice",
      2 => "Bob"
    }.each do |pair|
      db.execute "INSERT INTO test.test_table VALUES ( ?, ? )", pair
    end

    db.execute("INSERT INTO test.test_table (id, name)
                VALUES (?, ?)", ["3", "Charlie"])

    db.execute("INSERT INTO test.test_table (id, name) VALUES
                (4, 'David')")
  end

  describe '#open' do
    it 'open database without block' do
      db = ChDB::Database.open("file:#{test_db_path}")
      expect(db).to be_a(ChDB::Database)
      expect(db.closed?).to be false 
      expect(db.readonly?).to be false
      expect(db.results_as_hash).to be false
      db.close()
      expect(db.closed?).to be true 
    end  

    it 'auto-closes database with block' do
      db = nil
      ChDB::Database.open(test_db_path) do |database|
        db = database
        expect(db).to be_a(ChDB::Database)
        expect(db.closed?).to be false
        expect(db.readonly?).to be false
        expect(db.results_as_hash).to be false
      end
      expect(db.closed?).to be true
    end
    
    it 'raises error when open database' do
      db1 = ChDB::Database.open(test_db_path, results_as_hash: true)
      expect { ChDB::Database.new(test_db_path, results_as_hash: true) }.to raise_error(ChDB::InternalException, /Existing database/)
      expect { ChDB::Database.new(test_db_path2, results_as_hash: true) }.to raise_error(ChDB::InternalException, /Existing database/)
      db1.close()
      db2 = ChDB::Database.new(test_db_path2)
      result = db2.execute('SELECT 1 AS value')
      expect(result).to eq([["1"]])
      db2.close()
      
      db3 = ChDB::Database.new(test_db_path) 
      expect { ChDB::Database.new(test_db_path, results_as_hash: true) }.to raise_error(ChDB::InternalException, /Existing database/)
      db3.close()
      
      ChDB::Database.open(test_db_path) do |database|
        db = database
        expect(db).to be_a(ChDB::Database)
        expect(db.closed?).to be false
        expect(db.readonly?).to be false
        expect(db.results_as_hash).to be false
      end
      db4 = ChDB::Database.new(test_db_path) 
      db4.close()
    end
    
    it 'open, close, open database' do
      db = ChDB::Database.open(test_db_path)
      create_test_table(db)
      db.close()
      db = ChDB::Database.open(test_db_path)
      result = db.execute('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      db.close()
    end
  end

  describe '#execute' do
    it 'query empty table' do
      ChDB::Database.open(test_db_path) do |db|
        create_empty_table(db)
        result = db.execute('SELECT * FROM test.test_table')
        expect(result).to eq([])

        collected = []
        db.execute('SELECT * FROM test.test_table ORDER BY id') do |row|
          collected << row
        end
        expect(collected).to eq([])
      end
    end

    it 'returns query results with simple query' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        result = db.execute('SELECT 1 AS value')
        expect(result).to eq([{ 'value' => '1' }])
      end
      
      ChDB::Database.open(test_db_path) do |db|
        result = db.execute("SELECT number FROM system.numbers LIMIT 3")
        expect(result).to eq([["0"], ["1"], ["2"]])
      end
    end
    
    it 'handles positional parameters' do
      ChDB::Database.open(test_db_path) do |db|
        result = db.execute("SELECT ? * ? AS product", [6, 7])
        expect(result).to eq([["42"]])
      end
    end
    
    it 'processes different data types' do
      ChDB::Database.open(test_db_path) do |db|
        result = db.execute(
          "SELECT ?, ?, ?",
          ["O'Reilly", 3.14, false] 
        )
        expect(result).to eq([["O'Reilly", '3.14', '0']])
      end
    end
    
    it 'raises error when parameter count mismatch' do
      ChDB::Database.open(test_db_path) do |db|
        expect {
          db.execute("SELECT ? + ?", [10])
        }.to raise_error(ChDB::SQLException)
      end
      
      ChDB::Database.open(test_db_path) do |db|
        expect {
          db.execute("SELECT ? + ?", [10, 11, 22])
        }.to raise_error(ChDB::SQLException)
      end
    end

    it 'raises error when closed' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      db.close
      expect { db.execute('SELECT 1') }.to raise_error(ChDB::InvalidArgumentException, /closed database/)
    end

    it 'create table, insert rows, and returns query results' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        create_test_table(db)
        result = db.execute('SELECT * FROM test.test_table ORDER BY id')
        expect(result.to_a).to eq([{ 'id' => '1', 'name' => 'Alice' }, { 'id' => '2', 'name' => 'Bob' },
                                   { 'id' => '3', 'name' => 'Charlie' }, { 'id' => '4', 'name' => 'David' }])
      end
    end

    it 'yields rows with block' do
      collected = []
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      db.execute('SELECT * FROM test.test_table ORDER BY id') do |row|
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
      result = db.execute('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      db.close
    end
    
    it 'multi threads query' do
      ChDB::Database.open(test_db_path) do |db|
        create_test_table(db)
        
        expected_results = [%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]]
        thread_count = 5
        results = Array.new(thread_count, nil)
        threads = []
  
        thread_count.times do |i|
          threads << Thread.new do
            results[i] = db.execute("SELECT * FROM test.test_table ORDER BY id")
          end
        end
  
        threads.each(&:join)
  
        results.each do |result|
          expect(result).to eq(expected_results)
        end
      end
    end
    
    it 'multi threads query with params' do
      ChDB::Database.open(test_db_path) do |db|
        create_test_table(db)
  
        queries = [
          { sql: "SELECT name FROM test.test_table WHERE id = ? ORDER BY id", params: [1], expected: [["Alice"]] },
          { sql: "SELECT id FROM test.test_table WHERE name = ? ORDER BY id", params: ["Bob"], expected: [["2"]] },
          { sql: "SELECT * FROM test.test_table WHERE id > ? ORDER BY id", params: [2], expected: [%w[3 Charlie], %w[4 David]] }
        ]
  
        results = []
        threads = []
  
        queries.each_with_index do |q, idx| 
          threads << Thread.new do
            results[idx] = db.execute(q[:sql], q[:params]) 
          end
        end
  
        threads.each(&:join)
  
        expect(results[0]).to eq(queries[0][:expected])
        expect(results[1]).to eq(queries[1][:expected])
        expect(results[2]).to eq(queries[2][:expected])
      end
    end
  end

  describe '#execute2' do
    it 'query empty table' do
      ChDB::Database.open(test_db_path) do |db|
        create_empty_table(db)
        result = db.execute('SELECT * FROM test.test_table')
        expect(result).to eq([])

        collected = []
        db.execute('SELECT * FROM test.test_table ORDER BY id') do |row|
          collected << row
        end
        expect(collected).to eq([])
    end
    end  

    it 'returns query results with simple query' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        result = db.execute2('SELECT 1 AS value')
        expect(result).to eq([['value'], { 'value' => '1' }])
      end
      
      ChDB::Database.open(test_db_path) do |db|
        result = db.execute2("SELECT number FROM system.numbers LIMIT 2")
        expect(result).to eq([["number"], ["0"], ["1"]])
      end
    end
    
    it 'handles loose parameters' do
      ChDB::Database.open(test_db_path) do |db|
        result = db.execute2("SELECT ? || ? AS combined", "Hello", "World")
        expect(result).to eq([["combined"], ["HelloWorld"]])
      end
    end
    
    it 'processes array parameters with splat' do
      ChDB::Database.open(test_db_path) do |db|
        params = [41, 42]
        result = db.execute2("SELECT ?, ?", *params)
        expect(result[1]).to eq(['41', '42'])
      end
    end
    
    it 'yields headers and rows with block' do
      headers = []
      collected = []
      ChDB::Database.open(test_db_path) do |db|
        db.execute2("SELECT number, number+1 FROM system.numbers LIMIT 2") do |h|
          headers = h unless headers.any?
          collected << h
        end
      end
      expect(headers).to eq(["number", "plus(number, 1)"])
      expect(collected.size).to eq(3)
    end
    
    it 'returns hash results when results_as_hash enabled' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        result = db.execute2("SELECT 1 AS value")
        expect(result).to eq([["value"], { "value" => "1" }])
      end
    end
  
    it 'raises error with invalid parameter types' do
      ChDB::Database.open(test_db_path) do |db|
        expect {
          db.execute2("SELECT ?", Object.new)
        }.to raise_error(Exception)
      end
    end

    it 'raises error when closed' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      db.close
      expect { db.execute2('SELECT 1') }.to raise_error(ChDB::InvalidArgumentException, /closed database/)
    end

    it 'create table, insert rows, and returns query results' do
      ChDB::Database.open(test_db_path, results_as_hash: true) do |db|
        create_test_table(db)
        result = db.execute2('SELECT * FROM test.test_table ORDER BY id')
        expect(result.to_a).to eq([%w[id name], { 'id' => '1', 'name' => 'Alice' }, { 'id' => '2', 'name' => 'Bob' },
                                   { 'id' => '3', 'name' => 'Charlie' }, { 'id' => '4', 'name' => 'David' }])
      end
    end

    it 'yields rows with block' do
      collected = []
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      db.execute2('SELECT * FROM test.test_table ORDER BY id') do |row|
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
      result = db.execute2('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq([%w[id name], %w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      db.close
    end
    
    it 'multi threads query' do
      ChDB::Database.open(test_db_path) do |db|
        create_test_table(db)
        
        expected_results = [%w[id name], %w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]]
        thread_count = 5
        results = Array.new(thread_count, nil)
        threads = []
  
        thread_count.times do |i|
          threads << Thread.new do
            results[i] = db.execute2("SELECT * FROM test.test_table ORDER BY id")
          end
        end
  
        threads.each(&:join)
  
        results.each do |result|
          expect(result).to eq(expected_results)
        end
      end
    end
    
    it 'multi threads query with params' do
      ChDB::Database.open(test_db_path) do |db|
        create_test_table(db)
  
        queries = [
          { sql: "SELECT name FROM test.test_table WHERE id = ? ORDER BY id", params: [1], expected: [['name'], ['Alice']] },
          { sql: "SELECT id FROM test.test_table WHERE name = ? ORDER BY id", params: ["Bob"], expected: [['id'], ["2"]] },
          { sql: "SELECT * FROM test.test_table WHERE id > ? ORDER BY id", params: [2], expected: [%w[id name], %w[3 Charlie], %w[4 David]] }
        ]
  
        results = []
        threads = []
  
        queries.each_with_index do |q, idx| 
          threads << Thread.new do
            results[idx] = db.execute2(q[:sql], q[:params]) 
          end
        end
  
        threads.each(&:join)
  
        expect(results[0]).to eq(queries[0][:expected])
        expect(results[1]).to eq(queries[1][:expected])
        expect(results[2]).to eq(queries[2][:expected])
      end
    end
  end

  describe '#query' do
    it 'query' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.query('SELECT * FROM test.test_table ORDER BY id')
      expect(result.to_a).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
      
      result = db.query('SELECT * FROM test.test_table WHERE id != ? AND name != ? ORDER BY id', [0, 'Jack'])
      expect(result.to_a).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])

      db.close
    end
    
    it 'query empty table' do
      db = ChDB::Database.new(test_db_path)
      create_empty_table(db)
      result = db.query('SELECT * FROM test.test_table ORDER BY id')
      expect(result.to_a).to eq([])
      db.close
    end
  end

  describe '#query_with_format' do
    it 'query with format' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.query_with_format('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq("1,\"Alice\"\n2,\"Bob\"\n3,\"Charlie\"\n4,\"David\"\n")
      
      result = db.query_with_format('SELECT * FROM test.test_table WHERE id > ? ORDER BY id', 'CSV', [0])
      expect(result).to eq("1,\"Alice\"\n2,\"Bob\"\n3,\"Charlie\"\n4,\"David\"\n")
      db.close
    end
    
    it 'query with format and empty table' do
      db = ChDB::Database.new(test_db_path)
      create_empty_table(db)
      result = db.query_with_format('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq('')
      db.close
    end
  end

  describe '#get_first_row' do
    it 'get first row' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.get_first_row('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq(%w[1 Alice])
      db.close
    end

    it 'get first row with hash' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      result = db.get_first_row('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq({ 'id' => '1', 'name' => 'Alice' })
      db.close
    end
    
    it 'get first row with empty table' do
      db = ChDB::Database.new(test_db_path)
      create_empty_table(db)
      result = db.get_first_row('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq(nil)
      db.close
    end

    it 'get first row with empty table and hash' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_empty_table(db)
      result = db.get_first_row('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq(nil)
      db.close
    end
  end

  describe '#get_first_value' do
    it 'get first value' do
      db = ChDB::Database.new(test_db_path)
      create_test_table(db)
      result = db.get_first_value('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq('1')
      db.close
    end

    it 'get first value with hash' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_test_table(db)
      result = db.get_first_value('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq('1')
      db.close
    end
    
    it 'get first value with empty table' do
      db = ChDB::Database.new(test_db_path)
      create_empty_table(db)
      result = db.get_first_value('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq(nil)
      db.close
    end
    
    it 'get first value with empty table and hash' do
      db = ChDB::Database.new(test_db_path, results_as_hash: true)
      create_empty_table(db)
      result = db.get_first_value('SELECT * FROM test.test_table ORDER BY id')
      expect(result).to eq(nil)
      db.close
    end
  end

  describe '#prepare' do
    it 'creates reusable statement' do
      ChDB::Database.open(test_db_path) do |db|
        stmt = db.prepare('SELECT ? AS value')
        result = stmt.execute(42)
        expect(result.to_a).to eq([['42']])
        
        result = stmt.execute(55)
        expect(result.to_a).to eq([['55']])
        
        create_test_table(db)
        stmt = db.prepare('SELECT * FROM test.test_table WHERE id != ? AND name != ? ORDER BY id')
        result = stmt.execute([0, 'Jack'])
        expect(result.to_a).to eq([%w[1 Alice], %w[2 Bob], %w[3 Charlie], %w[4 David]])
        
        result = stmt.execute([2, 'Bob'])
        expect(result.to_a).to eq([%w[1 Alice], %w[3 Charlie], %w[4 David]])
        
        result = stmt.execute([false, 'Alice'])
        expect(result.to_a).to eq([%w[2 Bob], %w[3 Charlie], %w[4 David]])
        
        result = stmt.execute([true, 'Jack'])
        expect(result.to_a).to eq([%w[2 Bob], %w[3 Charlie], %w[4 David]])
        
        result = stmt.execute([nil, 'xx'])
        expect(result.to_a).to eq([])
      end
    end
  end
end
