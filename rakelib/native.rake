# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubygems/package_task"
require "rake/extensiontask"
require "rake_compiler_dock"
require "yaml"

cross_platforms = [
  "aarch64-linux-gnu",
  "x86_64-linux-gnu",
  "arm64-darwin",
  "x86_64-darwin"
]

RakeCompilerDock.set_ruby_cc_version("~> 3.1")

# Gem::PackageTask.new(CHDB_SPEC).define # packaged_tarball version of the gem for platform=ruby
task "package" => cross_platforms.map { |p| "gem:#{p}" } # "package" task for all the native platforms

module CHDBDependency
  class << self
    def setup
      dependencies = YAML.load_file(File.join(__dir__, "..", "dependencies.yml"), symbolize_names: true)
      chdb_info = dependencies[:chdb]
      version = chdb_info[:version]
      
      cross_platforms.each do |platform|
        platform_key = platform.gsub(/-/, '_').to_sym
        next unless chdb_info[:platforms][platform_key]
        
        download_and_extract(platform, version)
      end
    end

    private

    def download_and_extract(platform, version)
      file_name = case platform
                  when 'aarch64-linux-gnu' then 'linux-aarch64-libchdb.tar.gz'
                  when 'x86_64-linux-gnu' then 'linux-x86_64-libchdb.tar.gz'
                  when 'arm64-darwin'     then 'macos-arm64-libchdb.tar.gz'
                  when 'x86_64-darwin'    then 'macos-x86_64-libchdb.tar.gz'
                  end

      url = "https://github.com/chdb-io/chdb/releases/download/v#{version}/#{file_name}"
    
      archive_dir = File.join("ports", "archives")
      FileUtils.mkdir_p(archive_dir)
      
      tarball = File.join(archive_dir, name)
      unless File.exist?(tarball)
        puts "Downloading #{name}..."
        URI.open(url) do |remote|
          IO.copy_stream(remote, tarball)
        end
      end

      tmp_dir = File.join(archive_dir, "tmp_chdb")
      FileUtils.rm_rf(tmp_dir)
      FileUtils.mkdir_p(tmp_dir)
      
      system("tar xzf #{tarball} -C #{tmp_dir}")

      ext_chdb_path = File.expand_path("ext/chdb", __dir__)
      [%w[include *.h], %w[lib *.so], %w[lib *.dylib]].each do |(src_dir, pattern)|
        src = File.join(tmp_dir, src_dir, pattern)
        dest = File.join(ext_chdb_path, src_dir)
        FileUtils.mkdir_p(dest)
        FileUtils.cp_r(Dir.glob(src), dest, remove_destination: true)
      end

      # 清理临时目录
      FileUtils.rm_rf(tmp_dir)
    end
  end
end

def gem_build_path
  File.join("pkg", CHDB_SPEC.full_name)
end

def add_file_to_gem(relative_source_path)
  if relative_source_path.nil? || !File.exist?(relative_source_path)
    raise "Cannot find file '#{relative_source_path}'"
  end

  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
  rm_f(dest_path) if File.exist?(dest_path)
  safe_ln(relative_source_path, dest_path)

  CHDB_SPEC.files << relative_source_path
end

task gem_build_path do
  dependencies = YAML.load_file(File.join(__dir__, "..", "dependencies.yml"), symbolize_names: true)
  sqlite_tarball = File.basename(dependencies[:sqlite3][:files].first[:url])
  archive = Dir.glob(File.join("ports", "archives", sqlite_tarball)).first
  add_file_to_gem(archive)
end

Rake::ExtensionTask.new("chdb_native", CHDB_SPEC) do |ext|
  ext.ext_dir = "ext/chdb"
  ext.lib_dir = "lib/chdb"
  ext.cross_compile = true
  ext.cross_platform = cross_platforms
  ext.cross_config_options << "--enable-cross-build" # so extconf.rb knows we're cross-compiling
  
  ext.prerequisites << :download_chdb_deps
end

namespace "gem" do
  cross_platforms.each do |platform|
    desc "build native gem for #{platform}"
    task platform do
      RakeCompilerDock.sh(<<~EOF, platform: platform, verbose: true)
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake gem:#{platform}:buildit
      EOF
    end

    namespace platform do
      # this runs in the rake-compiler-dock docker container
      task "buildit" do
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{platform}"].invoke
        Rake::Task["pkg/#{CHDB_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end
    end
  end

  desc "build native gem for all platforms"
  task "all" => [cross_platforms, "gem"].flatten
end

desc "Temporarily set VERSION to a unique timestamp"
task "set-version-to-timestamp" do
  # this task is used by bin/test-gem-build
  # to test building, packaging, and installing a precompiled gem
  version_constant_re = /^\s*VERSION\s*=\s*["'](.*)["']$/

  version_file_path = File.join(__dir__, "../lib/chdb/version.rb")
  version_file_contents = File.read(version_file_path)

  current_version_string = version_constant_re.match(version_file_contents)[1]
  current_version = Gem::Version.new(current_version_string)

  fake_version = Gem::Version.new(format("%s.test.%s", current_version.bump, Time.now.strftime("%Y.%m%d.%H%M")))

  unless version_file_contents.gsub!(version_constant_re, "    VERSION = \"#{fake_version}\"")
    raise("Could not hack the VERSION constant")
  end

  File.write(version_file_path, version_file_contents)

  puts "NOTE: wrote version as \"#{fake_version}\""
end

CLEAN.add("{ext,lib}/**/*.{o,so}", "pkg", "ext/chdb/{include,lib}")

task :download_chdb_deps do
  CHDBDependency.setup
end
