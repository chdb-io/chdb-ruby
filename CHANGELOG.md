# chdb-ruby Changelog

## [Unreleased]

## [0.2.0] - 2026-11-05

- The engine is chDB core v26.11.0-rc.2 (ClickHouse 26.11), downloaded from
  chdb-io/chdb-core's releases during `gem install`; 0.1.0 used chdb 3.1.2.
- Streaming queries: results can be read chunk by chunk instead of all at once.
- Query, streaming, connection and library-loading errors are raised as
  `ChDB::Exception`, a `StandardError`, so `rescue => e` and `rescue ChDB::Exception`
  catch them; they were plain `::Exception` before.
