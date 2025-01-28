#!/usr/bin/env ruby
#
# convert-video.rb
#
# Copyright (c) 2025 Lisa Melton
#

require 'English'
require 'json'
require 'optparse'

module Converting

  class UsageError < RuntimeError
  end

  class Command
    def about
      <<-HERE
convert-video.rb 2025.01.28
Copyright (c) 2025 Lisa Melton
      HERE
    end

    def usage
      <<-HERE
Convert media file from Matroska to MP4 format or other media to MKV
without transcoding.

Usage: #{File.basename($PROGRAM_NAME)} [OPTION]... [FILE]...

All video, audio and subtitle tracks are copied during conversion.
But incompatible subtitles are ignored when converting to MP4 format.

Options:
    --debug           increase diagnostic information
-n, --dry-run         don't transcode, just show `ffmpeg` command
-h, --help            display this help and exit
    --version         output version information and exit

Requires `ffmpeg` and `ffprobe`.
      HERE
    end

    def initialize
      @debug = false
      @dry_run = false
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

      opts.on '-n', '--dry-run' do
        @dry_run = true
      end
    end

    def process_input(path)
      seconds = Time.now.tv_sec
      media_info = scan_media(path)
      options = ['-c:v', 'copy', '-c:a', 'copy']

      if media_info['format']['format_name'] =~ /matroska/
        extension = '.mp4'
        index = 0

        media_info['streams'].each do |stream|
          map_stream = false
          codec_name = nil

          case stream['codec_type']
          when 'video', 'audio'
            map_stream = true
          when 'subtitle'
            case stream['codec_name']
            when 'dvd_subtitle'
              map_stream = true
              codec_name = 'copy'
            when 'subrip'
              map_stream = true
              codec_name = 'mov_text'
            else
              Kernel.warn "Ignoring subtitle track \##{index + 1}"
            end

            index += 1
          end

          options += ['-map', "0:#{stream['index']}"] if map_stream
          options += ["-c:s:#{index - 1}", codec_name] unless codec_name.nil?
        end

        options += ['-movflags', 'disable_chpl']
      else
        extension = '.mkv'
        options += ['-c:s', 'copy']
      end

      output = File.basename(path, '.*') + extension

      ffmpeg_command = [
        'ffmpeg',
        '-loglevel', (@debug ? 'verbose' : 'error'),
        '-stats',
        '-i', path,
        *options,
        output
      ]

      command_line = escape_command(ffmpeg_command)
      Kernel.warn 'Command line:'

      if @dry_run
        puts command_line
        return
      end

      Kernel.warn command_line
      fail "output file already exists: #{output}" if File.exist? output

      Kernel.warn 'Converting...'
      system(*ffmpeg_command, exception: true)
      Kernel.warn "\nElapsed time: #{seconds_to_time(Time.now.tv_sec - seconds)}\n\n"
    end

    def scan_media(path)
      Kernel.warn 'Scanning media...'
      media_info = ''

      IO.popen([
        'ffprobe',
        '-loglevel', 'quiet',
        '-show_streams',
        '-show_format',
        '-print_format', 'json',
        path
      ]) do |io|
        media_info = io.read
      end

      fail "scanning media failed: #{path}" unless $CHILD_STATUS.exitstatus == 0

      begin
        media_info = JSON.parse(media_info)
      rescue JSON::JSONError
        fail "media information not found: #{path}"
      end

      Kernel.warn media_info.inspect if @debug
      media_info
    end

    def escape_command(command)
      command_line = ''
      command.each {|item| command_line += "#{escape_string(item)} " }
      command_line.sub!(/ $/, '')
      command_line
    end

def escape_string(str)
      # See: https://github.com/larskanis/shellwords
      return '""' if str.empty?

      str = str.dup

      if RUBY_PLATFORM =~ /mingw/
        str.gsub!(/((?:\\)*)"/) { "\\" * ($1.length * 2) + "\\\"" }

        if str =~ /\s/
          str.gsub!(/(\\+)\z/) { "\\" * ($1.length * 2 ) }
          str = "\"#{str}\""
        end
      else
        str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/, "\\\\\\1")
        str.gsub!(/\n/, "'\n'")
      end

      str
    end

    def seconds_to_time(seconds)
      sprintf("%02d:%02d:%02d", seconds / (60 * 60), (seconds / 60) % 60, seconds % 60)
    end
  end
end

Converting::Command.new.run
