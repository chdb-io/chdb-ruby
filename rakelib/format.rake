# frozen_string_literal: true

require 'rake/clean'

begin
  require 'rubocop/rake_task'

  module AstyleHelper
    class << self
      def run(files)
        assert
        command = ['astyle', args, files].flatten.shelljoin
        system(command)
      end

      def assert
        require 'mkmf'
        find_executable0('astyle') || raise("Could not find command 'astyle'")
      end

      def args
        indentation_args + bracket_args + space_args + pointer_args + function_args + limit_args + quiet_args
      end

      def indentation_args
        [
          '--indent=spaces=4',
          '--indent-switches'
        ]
      end

      def bracket_args
        [
          '--style=1tbs',
          '--style=allman',
          '--keep-one-line-blocks'
        ]
      end

      def space_args
        [
          '--unpad-paren',
          '--pad-header',
          '--pad-oper',
          '--pad-comma'
        ]
      end

      def pointer_args
        [
          '--align-pointer=name'
        ]
      end

      def function_args
        [
          '--attach-return-type',
          '--attach-return-type-decl'
        ]
      end

      def limit_args
        [
          '--max-code-length=120'
        ]
      end

      def quiet_args
        [
          '--formatted',
          '--verbose'
        ]
      end

      def c_files
        Dir.glob('ext/chdb/**/*.{c,h}')
      end
    end
  end

  namespace 'format' do
    desc 'Format C code'
    task 'c' do
      puts 'Running astyle on C files ...'
      AstyleHelper.run(AstyleHelper.c_files)
    end

    CLEAN.add(AstyleHelper.c_files.map { |f| "#{f}.orig" })

    desc 'Format Ruby code'
    task 'ruby' => 'rubocop:autocorrect'
  end

  RuboCop::RakeTask.new

  task 'format' => ['format:c', 'format:ruby']
rescue LoadError => e
  puts "NOTE: Rubocop is not available in this environment: #{e.message}"
end
