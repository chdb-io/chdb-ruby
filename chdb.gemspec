# frozen_string_literal: true

begin
  require_relative 'lib/chdb/version'
rescue LoadError
  puts 'WARNING: could not load ChDB::VERSION'
end

Gem::Specification.new do |s|
  s.name = 'chdb-ruby'
  s.version = defined?(ChDB::VERSION) ? ChDB::VERSION : '0.0.0'

  s.summary = 'Ruby library to interface with the chDB database engine (https://clickhouse.com/docs/chdb).'
  s.description = <<~TEXT
    Ruby library to interface with the chDB database engine (https://clickhouse.com/docs/chdb). Precompiled
    binaries are available for common platforms for recent versions of Ruby.
  TEXT

  s.authors = ['Xiaozhe Yu', 'Auxten Wang']

  s.licenses = ['Apache-2.0']

  s.required_ruby_version = Gem::Requirement.new('>= 3.1')

  s.homepage = 'https://github.com/chdb-io/chdb-ruby'
  s.metadata = {
    'homepage_uri' => 'https://github.com/chdb-io/chdb-ruby',
    'bug_tracker_uri' => 'https://github.com/chdb-io/chdb-ruby/issues',
    'changelog_uri' => 'https://github.com/chdb-io/chdb-ruby/blob/main/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/chdb-io/chdb-ruby',

    # https://guides.rubygems.org/mfa-requirement-opt-in/
    'rubygems_mfa_required' => 'true'
  }

  s.files = [
    # 'CHANGELOG.md',
    'INSTALLATION.md',
    'LICENSE',
    'README.md',
    'lib/chdb.rb',
    'lib/chdb/constants.rb',
    'lib/chdb/data_path.rb',
    'lib/chdb/database.rb',
    'lib/chdb/errors.rb',
    'lib/chdb/local_result.rb',
    'lib/chdb/parameter_binding.rb',
    'lib/chdb/result_handler.rb',
    'lib/chdb/result_set.rb',
    'lib/chdb/sql_processor.rb',
    'lib/chdb/statement.rb',
    'lib/chdb/version_info.rb',
    'lib/chdb/version.rb'
  ]

  s.rdoc_options = ['--main', 'README.md']

  s.add_dependency 'csv', '~> 3.1'

  # s.extensions << 'ext/chdb/extconf.rb'
end
