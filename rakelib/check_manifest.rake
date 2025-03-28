# frozen_string_literal: true

desc 'Perform a sanity check on the gemspec file list'
task :check_manifest do # rubocop:disable Metrics/BlockLength
  ignore_directories = %w{
    .DS_Store
    .bundle
    .git
    .github
    .ruby-lsp
    .vscode
    adr
    bin
    doc
    deps
    gems
    issues
    patches
    pkg
    ports
    rakelib
    spec
    test
    tmp
    vendor
    [0-9]*
  }
  ignore_files = %w[
    .editorconfig
    .gitignore
    .rdoc_options
    .rspec
    .rspec_status
    .ruby-version
    .rubocop.yml
    dependencies.yml
    ext/chdb/*.{c,h}
    lib/chdb/chdb*.{bundle,so}
    Gemfile*
    Rakefile
    [a-z]*.{log,out}
    [0-9]*
    *.gemspec
    *.so
    CHANGELOG.md
    ext/chdb/extconf.rb
  ]

  intended_directories = Dir.children('.')
                            .select { |filename| File.directory?(filename) }
                            .reject { |filename| ignore_directories.any? { |ig| File.fnmatch?(ig, filename) } }

  intended_files = Dir.children('.')
                      .select { |filename| File.file?(filename) }
                      .reject { |filename| ignore_files.any? { |ig| File.fnmatch?(ig, filename, File::FNM_EXTGLOB) } }

  intended_files += Dir.glob(intended_directories.map { |d| File.join(d, '/**/*') })
                       .select { |filename| File.file?(filename) }
                       .reject { |filename| ignore_files.any? { |ig| File.fnmatch?(ig, filename, File::FNM_EXTGLOB) } }
                       .sort

  spec_files = CHDB_SPEC.files.sort

  missing_files = intended_files - spec_files
  extra_files = spec_files - intended_files

  unless missing_files.empty?
    puts 'missing:'
    missing_files.sort.each { |f| puts "- #{f}" }
  end
  unless extra_files.empty?
    puts 'unexpected:'
    extra_files.sort.each { |f| puts "+ #{f}" }
  end
end
