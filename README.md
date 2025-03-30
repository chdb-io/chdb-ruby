<a href="https://chdb.io" target="_blank">
  <img src="https://avatars.githubusercontent.com/u/132536224" width=130 />
</a>

[![chDB-ruby](https://github.com/chdb-io/chdb-ruby/actions/workflows/chdb.yml/badge.svg)](https://github.com/chdb-io/chdb-ruby/actions/workflows/chdb.yml)

# Ruby Interface for chdb

## Overview

This library allows Ruby programs to use the chDB embedded analytical database (https://github.com/chdb-io/chdb).

**Designed with SQLite3-compatible API style** - If you're familiar with Ruby's sqlite3 gem, you'll feel right at home with chdb-ruby's similar interface design.

Note that this module is only compatible with ChDB 3.0.0 or newer.

* Source code: https://github.com/chdb-io/chdb-ruby
* Download: http://rubygems.org/gems/chdb-ruby
* Documentation: https://clickhouse.com/docs/chdb

## Quick start

``` ruby
require 'chdb'

# Open a database
db = ChDB::Database.new('test_db', results_as_hash: true)

# Create a table
rows = db.execute <<-SQL
  CREATE TABLE test_table(
    id Int32,
    name String)
    ENGINE = MergeTree()
    ORDER BY id);
SQL

# Execute a few inserts
{
      1 => 'Alice',
      2 => 'Bob'
}.each do |pair|
  db.execute 'INSERT INTO test_table VALUES ( ?, ? )', pair
end

# Find a few rows
db.execute('SELECT * FROM test_table ORDER BY id') do |row|
  p row
end
# [{ 'id' => '1', 'name' => 'Alice' },
#  { 'id' => '2', 'name' => 'Bob' }]

# Open another database
db = ChDB::Database.new 'test2.db'

# Create another table
rows = db.execute <<-SQL
  CREATE TABLE test2_table(
    id Int32,
    name String)
    ENGINE = MergeTree()
    ORDER BY id");
SQL

# Execute inserts with parameter markers
db.execute('INSERT INTO test2_table (id, name)
            VALUES (?, ?)', [3, 'Charlie'])

db.execute2('SELECT * FROM test2_table') do |row|
  p row
end
# [['id', 'name'], [3, 'Charlie']],
```

## Thread Safety

When using `ChDB::Database.new` to open a session, all read/write operations within that session are thread-safe. However, currently only one active session is allowed per process. Therefore, when you need to open another session, you must first close the previous session.

For example, the following code is fine because only the database
instance is shared among threads:

```ruby
require 'chdb'

db = ChDB::Database.new ":memory:'

latch = Queue.new

ts = 10.times.map {
  Thread.new {
    latch.pop
    db.execute 'SELECT 1'
  }
}
10.times { latch << nil }

p ts.map(&:value)
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
