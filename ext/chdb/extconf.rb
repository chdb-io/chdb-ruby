# frozen_string_literal: true

require 'fileutils'
require 'mkmf'
require 'yaml'

module ChDB
  module ExtConf
    class << self
      def configure
        configure_cross_compiler

        download_and_extract

        configure_extension

        create_makefile('chdb/chdb_native')
      end

      def configure_cross_compiler
        RbConfig::CONFIG['CC'] = RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']
        ENV['CC'] = RbConfig::CONFIG['CC']
      end

      def libname
        'chdb'
      end

      def configure_extension
        include_path = File.expand_path('ext/chdb/include', package_root_dir)
        append_cppflags("-I#{include_path}")

        lib_path = File.expand_path('ext/chdb/lib', package_root_dir)
        append_ldflags("-L#{lib_path}")

        append_ldflags("-Wl,-rpath,'$$ORIGIN/../lib'")

        abort_could_not_find('chdb.h') unless find_header('chdb.h', include_path)

        return if find_library(libname, nil, lib_path)

        abort_could_not_find(libname)
      end

      def abort_could_not_find(missing)
        message = <<~MSG
          Could not find #{missing}.
          Please visit https://github.com/chdb-io/chdb-ruby for installation instructions.
        MSG
        abort("\n#{message}\n")
      end

      def download_and_extract
        target_platform = determine_target_platform
        version = fetch_chdb_version
        download_dir = setup_download_directory(target_platform, version)

        unless Dir.exist?(download_dir)
          file_name = get_file_name(target_platform)
          url = build_download_url(version, file_name)
          download_tarball(url, download_dir, file_name)
          extract_tarball(download_dir, file_name)
        end

        copy_files(download_dir, version)
      end

      private

      def determine_target_platform
        ENV['TARGET'] || host_platform
      end

      def fetch_chdb_version
        dependencies = YAML.load_file(File.join(package_root_dir, 'dependencies.yml'), symbolize_names: true)
        dependencies[:chdb][:version]
      end

      def setup_download_directory(target_platform, version)
        download_dir = File.join(package_root_dir, 'deps', version, target_platform)
        FileUtils.mkdir_p(download_dir)
        download_dir
      end

      def get_file_name(target_platform)
        case target_platform
        when 'aarch64-linux-gnu' then 'linux-aarch64-libchdb.tar.gz'
        when 'x86_64-linux-gnu' then 'linux-x86_64-libchdb.tar.gz'
        when 'arm64-darwin'     then 'macos-arm64-libchdb.tar.gz'
        when 'x86_64-darwin'    then 'macos-x86_64-libchdb.tar.gz'
        else raise "Unsupported platform: #{target_platform}"
        end
      end

      def build_download_url(version, file_name)
        "https://github.com/chdb-io/chdb/releases/download/v#{version}/#{file_name}"
      end

      def download_tarball(url, download_dir, file_name)
        tarball = File.join(download_dir, file_name)
        puts "Downloading chdb library for #{determine_target_platform}..."
        URI.open(url) do |remote| # rubocop:disable Security/Open
          IO.copy_stream(remote, tarball)
        end
      end

      def extract_tarball(download_dir, file_name)
        tarball = File.join(download_dir, file_name)
        system("tar xzf #{tarball} -C #{download_dir}")
      end

      def copy_files(download_dir, _version)
        ext_chdb_path = File.join(package_root_dir, 'ext/chdb')
        [%w[include *.h], %w[lib *.so], %w[lib *.dylib]].each do |(src_dir, pattern)|
          src = File.join(download_dir, src_dir, pattern)
          dest = File.join(ext_chdb_path, src_dir)
          FileUtils.mkdir_p(dest)
          FileUtils.cp_r(Dir.glob(src), dest, remove_destination: true)
        end
      end

      def host_platform
        RbConfig::CONFIG['host_os'].downcase
      end

      def package_root_dir
        File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
      end
    end
  end
end

if arg_config('--download-dependencies')
  ChDB::ExtConf.download_and_extract
  exit!(0)
end

ChDB::ExtConf.configure
