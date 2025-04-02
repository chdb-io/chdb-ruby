# frozen_string_literal: true

require 'json' 
require 'spec_helper'

RSpec.describe ChDB::Statement do
  let(:test_db_path) { File.join(__dir__, 'testdb') }
  let(:db) { ChDB::Database.new(test_db_path) }

  before do
    db.execute('CREATE DATABASE IF NOT EXISTS test')
    db.execute('DROP TABLE IF EXISTS test.statement_test')
    db.execute(<<~SQL)
      CREATE TABLE test.statement_test(
        id Int32,
        name String,
        value Float32
      ) ENGINE = MergeTree()
      ORDER BY id
    SQL
  end

  after do
    db.close
  end

  describe '#execute' do
    it 'do basice query' do
      stmt = db.prepare("SELECT 1 AS value")
      result = stmt.execute
      expect(result.to_a).to eq([["1"]])
    end

    it 'do basice query with params' do
      stmt = db.prepare("SELECT ? + ? AS sum")
      expect(stmt.execute(3, 4).to_a).to eq([["7"]])
    end

    it 'do basice query with different types of params' do
      stmt = db.prepare("INSERT INTO test.statement_test VALUES (?, ?, ?)")
      time = Time.now
      
      expect {
        stmt.execute(1, "O'Reilly", 3.14)
      }.not_to raise_error

      result = db.execute("SELECT * FROM test.statement_test")
      expect(result.first).to eq(["1", "O'Reilly", "3.14"])
    end

    it 'raises error when parameter count mismatch' do
      stmt = db.prepare("SELECT ?, ?")
      expect { stmt.execute(1) }.to raise_error(ChDB::SQLException)
      expect { stmt.execute(1, 2, 3) }.to raise_error(ChDB::SQLException)
      expect {
        stmt.execute(1, 2)
      }.not_to raise_error
    end

    it 'show tables' do
      stmt = db.prepare("USE test")
      expect {
        stmt.execute()
      }.not_to raise_error
      
      stmt = db.prepare("SHOW TABLES")
      expect(stmt.execute().to_a).to satisfy { |result|
        result.any? { |row| row == ['statement_test'] }
      }

      stmt = db.prepare('DROP TABLE statement_test')
      expect {
        stmt.execute()
      }.not_to raise_error
     
      stmt = db.prepare('SHOW TABLES')
      expect(stmt.execute().to_a).not_to include(['statement_test'])
    end
  end

  describe '#execute!' do
    it 'return array result' do
      stmt = db.prepare("SELECT number FROM system.numbers LIMIT 3")
      expect(stmt.execute!).to eq([['0'], ['1'], ['2']])
    end
    
    it 'return hash array when results_as_hash enabled' do
      db.close()
      hash_db = ChDB::Database.new(test_db_path, results_as_hash: true)
      
      begin
        stmt = hash_db.prepare("SELECT 1 AS value, 'hello' AS greeting")
        result = stmt.execute!
        expect(result).to eq([['1', 'hello']])
      ensure
        hash_db.close
      end
    end

    it 'block iter' do
      stmt = db.prepare("SELECT number FROM system.numbers LIMIT 3")
      collected = []
      stmt.execute! { |row| collected << row }
      expect(collected).to eq([['0'], ['1'], ['2']])
    end
  end

  describe '#execute_with_format' do
    it 'CSV format' do
      stmt = db.prepare("SELECT 1 AS a, 2 AS b FORMAT CSV")
      result = stmt.execute_with_format('CSV')
      expect(result).to eq("1,2\n")
    end

    it 'JSON format' do
      stmt = db.prepare("SELECT 1 AS a, 2 AS b FORMAT JSON")
      result = stmt.execute_with_format('JSON')
      expect(JSON.parse(result).except("statistics")).to eq({
        "meta" => [{"name" => "a", "type" => "UInt8"}, {"name" => "b", "type" => "UInt8"}],
        "data" => [{"a" => 1, "b" => 2}],
        "rows" => 1
      })
    end
  end

  describe 'reuse statment' do
    it 'execute with different params' do
      stmt = db.prepare("SELECT ? * ? AS product")
      expect(stmt.execute(6, 7).to_a).to eq([["42"]])
      expect(stmt.execute(0.5, 4).to_a).to eq([["2"]])
    end

    it 'execute after reset' do
      stmt = db.prepare("SELECT ?")
      expect(stmt.execute(1).to_a).to eq([["1"]])
      stmt.reset!
      expect(stmt.execute(2).to_a).to eq([["2"]])
    end
  end
end
