#!/usr/bin/env ruby
#
# detect-crop.rb
#
# Copyright (c) 2025 Lisa Melton
#

require 'English'
require 'open3'
require 'optparse'
require 'tempfile'

module Cropping

  class UsageError < RuntimeError
  end

  class Command
    def about
      <<-HERE
detect-crop.rb 2025.01.28
Copyright (c) 2025 Lisa Melton
      HERE
    end

    def usage
      <<-HERE
Detect unused outside area of video tracks.

Usage: #{File.basename($PROGRAM_NAME)} [OPTION]... [FILE]...

Prints TOP:BOTTOM:LEFT:RIGHT crop values to standard output

Options:
-m, --mode auto|conservative
                      set crop mode (default: conservative)
-h, --help            display this help and exit
    --version         output version information and exit

Requires `HandBrakeCLI`.
      HERE
    end

    def initialize
      @input_count = 0
      @mode = 'conservative'
    end

    def run
      begin
        OptionParser.new do |opts|
          define_options opts

          opts.on '-h', '--help' do
            puts usage
            exit
          end

          opts.on '--version' do
            puts about
            exit
          end
        end.parse!
      rescue OptionParser::ParseError => e
        raise UsageError, e
      end

      fail UsageError, 'missing argument' if ARGV.empty?

      @input_count = ARGV.count
      ARGV.each { |arg| process_input arg }
      exit
    rescue UsageError => e
      Kernel.warn "#{$PROGRAM_NAME}: #{e}"
      Kernel.warn "Try `#{File.basename($PROGRAM_NAME)} --help` for more information."
      exit false
    rescue StandardError => e
      Kernel.warn "#{$PROGRAM_NAME}: #{e}"
      exit(-1)
    rescue SignalException
      puts
      exit(-1)
    end

    def define_options(opts)
      opts.on '--debug' do
        @debug = true
      end

      opts.on '-m', '--mode ARG' do |arg|
        @mode = case arg
        when 'auto', 'conservative'
          arg
        else
          fail UsageError, "unsupported crop mode: #{arg}"
        end
      end
    end

    def process_input(path)
      output = Tempfile.new('detect-crop')

      begin
        unused, info, status = Open3.capture3(
          'HandBrakeCLI',
          '--input', path,
          '--output', output.path,
          '--format', 'av_mkv',
          '--stop-at', 'seconds:1',
          '--crop-mode', @mode,
          '--encoder', 'x265_10bit',
          '--encoder-preset', 'ultrafast',
          '--audio', '0'
        )
        fail "scanning media failed: #{path}" unless status.exitstatus == 0
      ensure
        output.close
        output.unlink
      end

      crop = '0:0:0:0'

      info.each_line do |line|
        next unless line.valid_encoding?

        if line =~ %r{, crop \((\d+/\d+/\d+/\d+)\): }
          crop = $1.gsub('/', ':')
          break
        end
      end

      puts crop + (@input_count > 1 ? ",\"#{path.gsub(/"/, '""')}\"" : '')
    end
  end
end

Cropping::Command.new.run
