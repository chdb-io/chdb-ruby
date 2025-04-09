<a href="https://chdb.io" target="_blank">
  <img src="img/chdb-ruby.png" width=130 />
</a>


# Ruby binding for chDB

## Overview

This library allows Ruby programs to use the chDB embedded analytical database (https://github.com/chdb-io/chdb).

**Designed with SQLite3-compatible API style** - If you're familiar with Ruby's sqlite3 gem, you'll feel right at home with chdb-ruby's similar interface design.

Note that this module is only compatible with ChDB 3.0.0 or newer.

* Source code: https://github.com/chdb-io/chdb-ruby
* Download: http://rubygems.org/gems/chdb-ruby
* Documentation: https://clickhouse.com/docs/chdb

## Quick start

Before using chdb-ruby, install the gem first. This will download the libchdb C++ library dependencies, so please be patient:
```bash
gem install chdb-ruby
```

Below are examples of common interfaces usage:

```ruby
require 'chdb'

# Open a database
# Parameter explanation:
# 1. path supports two formats:
#    - ":memory:" in-memory temporary database (data destroyed on close)
#    - "file:/path/to/db" file-based persistent database
#    Configuration parameters can be appended via URL-style query (e.g. 'file:test.db?results_as_hash=true')
# 2. options hash supports:
#    - results_as_hash: controls whether result sets return as hashes (default: arrays)
db = ChDB::Database.new('file:test.db', results_as_hash: true)

# Create a database
db.execute('CREATE DATABASE IF NOT EXISTS test')

# Create a table
db.execute('DROP TABLE IF EXISTS test.test_table')
rows = db.execute <<-SQL
  CREATE TABLE test.test_table(
    id Int32,
    name String)
    ENGINE = MergeTree()
    ORDER BY id
SQL

# Execute a few inserts
{
  1 => 'Alice',
  2 => 'Bob'
}.each do |pair|
  db.execute 'INSERT INTO test.test_table VALUES ( ?, ? )', pair
end

# Find a few rows
db.execute('SELECT * FROM test.test_table ORDER BY id') do |row|
  p row
end
# [{ 'id' => '1', 'name' => 'Alice' },
#  { 'id' => '2', 'name' => 'Bob' }]

# When you need to open another database, you must first close the previous database 
db.close()

# Open another database
db = ChDB::Database.new 'file:test.db'

# Create another table
db.execute('DROP TABLE IF EXISTS test.test2_table')
rows = db.execute <<-SQL
  CREATE TABLE test.test2_table(
    id Int32,
    name String)
    ENGINE = MergeTree()
    ORDER BY id
SQL

# Execute inserts with parameter markers
db.execute('INSERT INTO test.test2_table (id, name)
            VALUES (?, ?)', [3, 'Charlie'])

# Find rows with the first row displaying column names
db.execute2('SELECT * FROM test.test2_table') do |row|
  p row
end
# ["id", "name"]
# ["3", "Charlie"]

# Close the database
db.close()

# Use ChDB::Database.open to automatically close the database connection:
ChDB::Database.open('file:test.db') do |db|
  result = db.execute('SELECT 1')
  p result.to_a # => [["1"]]
end

# Query with specific output formats (CSV, JSON, etc.):
# See more details at https://clickhouse.com/docs/interfaces/formats.
ChDB::Database.open(':memory:') do |db|
  csv_data = db.query_with_format('SELECT 1 as a, 2 as b', 'CSV')
  p csv_data
  # "1,2\n"

  json_data = db.query_with_format('SELECT 1 as a, 2 as b', 'JSON')
  p json_data
end
```

## Thread Safety

When using `ChDB::Database.new` or `ChDB::Database.open` to open a database connection, all read/write operations within that session are thread-safe. However, currently only one active database connection is allowed per process. Therefore, when you need to open another database connection, you must first close the previous connection.
**Please note that `ChDB::Database.new`, `ChDB::Database.open`, and `ChDB::Database.close` methods themselves are not thread-safe.** If used in multi-threaded environments, external synchronization must be implemented to prevent concurrent calls to these methods, which could lead to undefined behavior.

```ruby
require 'chdb'

db = ChDB::Database.new ':memory:'

latch = Queue.new

ts = 10.times.map {
  Thread.new {
    latch.pop
    db.execute 'SELECT 1'
  }
}
10.times { latch << nil }

p ts.map(&:value)
# [[["1"]], [["1"]], [["1"]], [["1"]], [["1"]], [["1"]], [["1"]], [["1"]], [["1"]], [["1"]]]

db.close()
```

Other instances can be shared among threads, but they require that you provide
your own locking for thread safety.  For example, `ChDB::Statement` objects
(prepared statements) are mutable, so applications must take care to add
appropriate locks to avoid data race conditions when sharing these objects
among threads.

It is generally recommended that if applications want to share a database among
threads, they _only_ share the database instance object. Other objects are
fine to share, but may require manual locking for thread safety.

## Support

### Installation

If you're having trouble with installation, please first read [`INSTALLATION.md`](./INSTALLATION.md).

### Bug reports

You can file the bug at the [github issues page](https://github.com/chdb-io/chdb-ruby/issues).

## License

This library is licensed under `Apache License 2.0`, see [`LICENSE`](./LICENSE).

## Acknowledgments
Special thanks to the following projects:

* [chDB 2.0 Ruby client](https://github.com/g3ortega/chdb) – As the foundational work for chDB 2.0, its design and architecture inspired this chDB 3.0 Ruby client.
* [SQLite3](https://github.com/sparklemotion/sqlite3-ruby) – We adopted patterns from its elegant Ruby API design.
