# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubygems/package_task'
require 'rake/extensiontask'
require 'rake_compiler_dock'
require 'yaml'

cross_platforms = %w[
  aarch64-linux-gnu
  x86_64-linux-gnu
  arm64-darwin
  x86_64-darwin
]

RakeCompilerDock.set_ruby_cc_version('~> 3.1')

# Gem::PackageTask.new(CHDB_SPEC).define # packaged_tarball version of the gem for platform=ruby
# 'package' task for all the native platforms
task 'package' => cross_platforms.map { |p| "gem:#{p}" }

def gem_build_path
  File.join('pkg', CHDB_SPEC.full_name)
end

def add_file_to_gem(relative_source_path)
  raise "Cannot find file '#{relative_source_path}'" if relative_source_path.nil? || !File.exist?(relative_source_path)

  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
  rm_f(dest_path) if File.exist?(dest_path)
  safe_ln(relative_source_path, dest_path)

  CHDB_SPEC.files << relative_source_path
end

task gem_build_path do
  dependencies = YAML.load_file(File.join(__dir__, '..', 'dependencies.yml'), symbolize_names: true)
  sqlite_tarball = File.basename(dependencies[:sqlite3][:files].first[:url])
  archive = Dir.glob(File.join('ports', 'archives', sqlite_tarball)).first
  add_file_to_gem(archive)
end

Rake::ExtensionTask.new('chdb_native', CHDB_SPEC) do |ext|
  ext.ext_dir = 'ext/chdb'
  ext.lib_dir = 'lib/chdb'
end

namespace 'gem' do
  cross_platforms.each do |platform|
    desc "build native gem for #{platform}"
    task platform do
      RakeCompilerDock.sh(<<~COMMAND_END, platform: platform, verbose: true)
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake gem:#{platform}:buildit
      COMMAND_END
    end

    namespace platform do
      # this runs in the rake-compiler-dock docker container
      task 'buildit' do
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{platform}"].invoke
        Rake::Task["pkg/#{CHDB_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end
    end
  end

  desc 'build native gem for all platforms'
  task 'all' => [cross_platforms, 'gem'].flatten
end

desc 'Temporarily set VERSION to a unique timestamp'
task 'set-version-to-timestamp' do
  # this task is used by bin/test-gem-build
  # to test building, packaging, and installing a precompiled gem
  version_constant_re = /^\s*VERSION\s*=\s*["'](.*)["']$/

  version_file_path = File.join(__dir__, '../lib/chdb/version.rb')
  version_file_contents = File.read(version_file_path)

  current_version_string = version_constant_re.match(version_file_contents)[1]
  current_version = Gem::Version.new(current_version_string)

  bumped_version = current_version.bump
  timestamp = Time.now.strftime('%Y.%m%d.%H%M')
  fake_version = Gem::Version.new(format('%<bumped_version>s.test.%<timestamp>s',
                                         bumped_version: bumped_version,
                                         timestamp: timestamp))

  unless version_file_contents.gsub!(version_constant_re, "    VERSION = \"#{fake_version}\"")
    raise('Could not hack the VERSION constant')
  end

  File.write(version_file_path, version_file_contents)

  puts "NOTE: wrote version as \"#{fake_version}\""
end

CLEAN.add('ext/chdb/{include,lib}')
