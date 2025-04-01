# frozen_string_literal: true

require 'fileutils'
require 'mkmf'
require 'yaml'
require 'open-uri'

module ChDB
  module ExtConf
    class << self
      def configure
        configure_cross_compiler

        download_and_extract

        configure_extension

        create_makefile('chdb/chdb_native')
      end

      def compiled?
        return false if cross_build?

        major_version = RUBY_VERSION.match(/(\d+\.\d+)/)[1]
        version_dir = File.join(package_root_dir, 'lib', 'chdb', major_version)

        extension = if determine_target_platform.include?('darwin')
                      'bundle'
                    else
                      'so'
                    end
        lib_file = "#{libname}.#{extension}"

        File.exist?(File.join(version_dir, lib_file))
      end

      def configure_cross_compiler
        RbConfig::CONFIG['CC'] = RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']
        ENV['CC'] = RbConfig::CONFIG['CC']
      end

      def cross_build?
        enable_config('cross-build')
      end

      def libname
        'chdb_native'
      end

      def configure_extension
        include_path = File.expand_path('ext/chdb/include', package_root_dir)
        append_cppflags("-I#{include_path}")
        abort_could_not_find('chdb.h') unless find_header('chdb.h', include_path)
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
        download_dir = determine_download_directory(target_platform, version)
        need_download = false

        if Dir.exist?(download_dir)
          required_files = [
            File.join(download_dir, 'chdb.h'),
            File.join(download_dir, 'libchdb.so')
          ]

          need_download = !required_files.all? { |f| File.exist?(f) }
          if need_download
            puts 'Missing required files, cleaning download directory...'
            FileUtils.rm_rf(Dir.glob("#{download_dir}/*"))
          end
        else
          FileUtils.mkdir_p(download_dir)
          need_download = true
        end

        if need_download
          file_name = get_file_name(target_platform)
          url = build_download_url(version, file_name)
          download_tarball(url, download_dir, file_name)
          extract_tarball(download_dir, file_name)
        end

        copy_files(download_dir, version)
      end

      private

      def determine_target_platform
        return ENV['TARGET'].strip if ENV['TARGET'] && !ENV['TARGET'].strip.empty?

        case RUBY_PLATFORM
        when /aarch64-linux/ then 'aarch64-linux'
        when /x86_64-linux/  then 'x86_64-linux'
        when /arm64-darwin/  then 'arm64-darwin'
        when /x86_64-darwin/ then 'x86_64-darwin'
        else
          raise ArgumentError, "Unsupported platform: #{RUBY_PLATFORM}."
        end
      end

      def fetch_chdb_version
        dependencies = YAML.load_file(File.join(package_root_dir, 'dependencies.yml'), symbolize_names: true)
        dependencies[:chdb][:version]
      end

      def determine_download_directory(target_platform, version)
        File.join(package_root_dir, 'deps', version, target_platform)
      end

      def get_file_name(target_platform)
        case target_platform
        when 'aarch64-linux' then 'linux-aarch64-libchdb.tar.gz'
        when 'x86_64-linux' then 'linux-x86_64-libchdb.tar.gz'
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

        max_retries = 3
        retries = 0

        begin
          URI.open(url) do |remote| # rubocop:disable Security/Open
            IO.copy_stream(remote, tarball)
          end
        rescue StandardError => e
          raise "Failed to download after #{max_retries} attempts: #{e.message}" unless retries < max_retries

          retries += 1
          puts "Download failed: #{e.message}. Retrying (attempt #{retries}/#{max_retries})..."
          retry
        end
      end

      def extract_tarball(download_dir, file_name)
        tarball = File.join(download_dir, file_name)
        system("tar xzf #{tarball} -C #{download_dir}")
      end

      def copy_files(download_dir, _version)
        [%w[*.h], %w[*.so]].each do |(glob_pattern)|
          # Removed the unused variable src_dir
          pattern = File.basename(glob_pattern)
          dest_subdir = case pattern
                        when '*.h' then 'include'
                        else 'lib'
                        end
          dest_dir = File.join(package_root_dir, 'ext/chdb', dest_subdir)
          src_files = Dir.glob(File.join(download_dir, pattern))

          extra_dirs = []
          extra_dirs << File.join(package_root_dir, 'lib/chdb/lib') if pattern == '*.so'

          ([dest_dir] + extra_dirs).each do |dest|
            FileUtils.mkdir_p(dest)

            src_files.each do |src_file|
              dest_file = File.join(dest, File.basename(src_file))
              FileUtils.ln_s(File.expand_path(src_file), dest_file, force: true)
            end
          end
        end
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
