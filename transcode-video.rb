#!/usr/bin/env ruby
#
# transcode-video.rb
#
# Copyright (c) 2025 Lisa Melton
#

require 'English'
require 'json'
require 'optparse'

module Transcoding

  class UsageError < RuntimeError
  end

  class Command
    def about
      <<-HERE
transcode-video.rb 2025.01.28
Copyright (c) 2025 Lisa Melton
      HERE
    end

    def usage
      <<-HERE
Transcode essential media tracks into a smaller, more portable format
while remaining high enough quality to be mistaken for the original.

Usage: #{File.basename($PROGRAM_NAME)} [OPTION]... [FILE]...

Creates a Matroska `.mkv` format file in the current working directory
with video in 8-bit H.264 format and audio in multichannel AAC format.
Forced subtitles are automatically burned or included.

Options:
    --debug           increase diagnostic information
-n, --dry-run         don't transcode, just show `HandBrakeCLI` command
-m, --mode h264|hevc|nvenc-hevc|av1|nvenc-av1|none
                      set video encoding mode (default: h264)
-p, --preset NAME     apply video encoder preset (default: 8 for av1)
-b, --bitrate TARGET  set video bitrate target (default: based on input)
-q, --quality VALUE   set constant quality value
    --no-bframe-refs  don't use B-frames as reference frames
                        (for compatibilty with older Nvidia GPUs)
-a, --audio-mode aac|opus|eac3|none
                      set audio encoding mode
                        (default: aac, opus for av1 and nvenc-av1)
    --add-audio TRACK|LANGUAGE|STRING|all
                      include audio track (default: 1)
                        (can be used multiple times)
    --ac3-surround    use AC-3 format for more compatible surround audio
                        (aac mode only, raises default audio bitrate)
    --aac-encoder av_aac|fdk_aac|ca_aac
                      select named AAC audio encoder (default: av_aac)
    --burn-subtitle TRACK|none
                      burn subtitle track into video (default: automatic)
                        (text-only subtitles are included, not burned)
    --add-subtitle TRACK|LANGUAGE|STRING|all
                      include subtitle track (disables burning)
                        (can be used multiple times)
-x, --extra NAME[=VALUE]
                      add `HandBrakeCLI` option by name or name with value
-h, --help            display this help and exit
    --version         output version information and exit

Requires `HandBrakeCLI` and `ffprobe`.
      HERE
    end

    def initialize
      @debug = false
      @dry_run = false
      @mode = :h264
      @preset = nil
      @bitrate = nil
      @quality = nil
      @bframe_refs = true
      @audio_mode = :aac
      @audio_selections = [{
        :track => 1,
        :language => nil,
        :title => nil
      }]
      @ac3_surround = false
      @aac_encoder = 'av_aac'
      @burn_subtitle = :auto
      @subtitle_selections = []
      @extra_options = {}
      @vbv_size = nil
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

      configure
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

      opts.on '-m', '--mode ARG' do |arg|
        @mode = case arg
        when 'h264', 'hevc', 'none'
          arg.to_sym
        when 'nvenc-hevc'
          :nvenc_hevc
        when 'av1'
          @audio_mode = :opus
          :av1
        when 'nvenc-av1'
          @audio_mode = :opus
          :nvenc_av1
        else
          fail UsageError, "unsupported video mode: #{arg}"
        end
      end

      opts.on '-p', '--preset ARG' do |arg|
        @preset = arg
      end

      opts.on '-b', '--bitrate ARG', Integer do |arg|
        @bitrate = arg.to_s
        @quality = nil
      end

      opts.on '-q', '--quality ARG', Float do |arg|
        @quality = arg.to_s
        @bitrate = nil
      end

      opts.on '--no-bframe-refs' do
        @bframe_refs = false
      end

      opts.on '-a', '--audio-mode ARG' do |arg|
        @audio_mode = case arg
        when 'aac', 'opus', 'eac3', 'none'
          arg.to_sym
        else
          fail UsageError, "unsupported audio mode: #{arg}"
        end
      end

      opts.on '--add-audio ARG' do |arg|
        selection = {
          :track => nil,
          :language => nil,
          :title => nil
        }

        case arg
        when /^[0-9]+$/
          selection[:track] = arg.to_i
        when /^[a-z]{3}$/
          selection[:language] = arg
        else
          selection[:title] = arg
        end

        @audio_selections += [selection]
      end

      opts.on '--ac3-surround' do
        @ac3_surround = true
      end

      opts.on '--aac-encoder ARG' do |arg|
        @aac_encoder = case arg
        when 'av_aac', 'fdk_aac', 'ca_aac'
          arg
        else
          fail UsageError, "invalid AAC audio encoder name: #{arg}"
        end
      end

      opts.on '--burn-subtitle ARG' do |arg|
        @burn_subtitle = case arg
        when /^[0-9]+$/
          @subtitle_selections = []
          arg.to_i
        when 'none'
          nil
        else
          fail UsageError, "invalid burn subtitle argument: #{arg}"
        end
      end

      opts.on '--add-subtitle ARG' do |arg|
        selection = {
          :track => nil,
          :language => nil,
          :title => nil
        }

        case arg
        when /^[0-9]+$/
          selection[:track] = arg.to_i
        when /^[a-z]{3}$/
          selection[:language] = arg
        else
          selection[:title] = arg
        end

        @subtitle_selections += [selection]
        @burn_subtitle = nil
      end

      opts.on '-x', '--extra ARG' do |arg|
        unless arg =~ /^([a-zA-Z][a-zA-Z0-9-]+)(?:=(.+))?$/
          fail UsageError, "invalid HandBrakeCLI option: #{arg}"
        end

        name = $1
        value = $2

        case name
        when 'help', 'version', 'json', /^preset/, 'queue-import-file',
          'input', 'output', /^encoder-[^-]+-list$/
          fail UsageError, "unsupported HandBrakeCLI option name: #{name}"
        end

        @extra_options[name] = value
      end
    end

    def configure
      @audio_selections.uniq!
      @subtitle_selections.uniq!
    end

    def process_input(path)
      seconds = Time.now.tv_sec

      if @extra_options.include? 'scan'
        handbrake_command = [
          'HandBrakeCLI',
          '--input', path
        ]

        @extra_options.each do |name, value|
          handbrake_command << "--#{name}"
          handbrake_command << value unless value.nil?
        end

        system(*handbrake_command, exception: true)
        return
      end

      extension = '.mkv'

      if @extra_options.include? 'format'
        @extra_options.each do |name, value|
          if name == 'format' and not value.nil?
            extension = case value
            when 'av_mkv', 'av_mp4', 'av_webm'
              '.' + value.sub(/^av_/, '')
            else
              fail UsageError, "unsupported HandBrakeCLI format: #{value}"
            end
          end
        end
      end

      output = File.basename(path, '.*') + extension
      media_info = scan_media(path)
      video_options = get_video_options(media_info)
      audio_options = get_audio_options(media_info)
      subtitle_options = get_subtitle_options(media_info)

      handbrake_command = [
        'HandBrakeCLI',
        '--input', path,
        '--output', output,
        *video_options,
        *audio_options,
        *subtitle_options
      ]

      encoder_options = nil

      unless @extra_options.include? 'encoder'
        case @mode
        when :h264
          encoder_options = "vbv-maxrate=#{@vbv_size}:vbv-bufsize=#{@vbv_size}"
        when :nvenc_hevc
          encoder_options = 'spatial_aq=1:rc-lookahead=20'
          encoder_options += ':b_ref_mode=2' if @bframe_refs
        when :nvenc_av1
          encoder_options = 'spatial-aq=1:rc-lookahead=20'
          encoder_options += ':b_ref_mode=2' if @bframe_refs
        end
      end

      @extra_options.each do |name, value|
        handbrake_command << "--#{name}"

        if name == 'encopts'
          fail UsageError, "invalid HandBrakeCLI option usage: #{name}" if value.nil?

          handbrake_command << (encoder_options.nil? ? value : "#{encoder_options}:#{value}")
          encoder_options = nil
        else
          handbrake_command << value unless value.nil?
        end
      end

      handbrake_command += ['--encopts', encoder_options] unless encoder_options.nil?
      command_line = escape_command(handbrake_command)
      Kernel.warn 'Command line:'

      if @dry_run
        puts command_line
        return
      end

      Kernel.warn command_line
      fail "output file already exists: #{output}" if File.exist? output

      Kernel.warn 'Transcoding...'
      system(*handbrake_command, exception: true)
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

    def get_video_options(media_info)
      video = nil

      media_info['streams'].each do |stream|
        if stream['codec_type'] == 'video'
          video = stream
          break
        end
      end

      return [] if video.nil?

      options = []
      preset  = @preset
      bitrate = @bitrate
      quality = @quality

      unless @extra_options.include? 'encoder'
        encoder = nil
        quality = [[@quality.to_f, 1.0].max, 51.0].min.to_s.sub(/\.0$/, '') unless @quality.nil?

        case @mode
        when :h264
          encoder = 'x264'
          width   = video['width'].to_i
          height  = video['height'].to_i

          if width > 1280 or height > 720
            bitrate = 5000

            if width > 1920 or height > 1080
              options += [
                '--maxWidth',   '1920',
                '--maxHeight',  '1080',
                '--loose-anamorphic'
              ]

              options += ['--colorspace', 'bt709'] if video.fetch('color_space', 'bt709') != 'bt709'
            end
          elsif width > 720 or height > 576
            bitrate = 2500
          else
            bitrate = 1250
          end

          @vbv_size = bitrate * 3

          if @quality.nil?
            bitrate = [[@bitrate.to_i,
                        (bitrate * 0.8).to_i].max,
                        (bitrate * 1.6).to_i].min unless @bitrate.nil?
            bitrate = bitrate.to_s
            options += ['--multi-pass', '--turbo']
          else
            bitrate = nil
          end
        when :hevc
          encoder = 'x265_10bit'
          quality ||= '24' if @bitrate.nil?
        when :nvenc_hevc
          encoder = 'nvenc_h265_10bit'
          quality ||= '30' if @bitrate.nil?
        when :av1
          encoder = 'svt_av1_10bit'

          if @bitrate.nil?
            quality = @quality.nil? ? '30' : [[@quality.to_i, 0].max, 63].min.to_s
          end

          preset = @preset.nil? ? '8' : [[@preset.to_i, -1].max, 13].min.to_s
        when :nvenc_av1
          encoder = 'nvenc_av1_10bit'

          if @bitrate.nil?
            quality = @quality.nil? ? '37' : [[@quality.to_i, 0].max, 63].min.to_s
          end
        else
          quality = @quality
        end

        options += ['--encoder', encoder] unless encoder.nil?
      end

      options += ['--encoder-preset', preset] unless preset.nil?
      options += ['--vb', bitrate]            unless bitrate.nil?
      options += ['--quality', quality]       unless quality.nil?

      unless  @extra_options.include? 'rate'  or
              @extra_options.include? 'vfr'   or
              @extra_options.include? 'cfr'   or
              @extra_options.include? 'pfr'
        if video['codec_name'] == 'mpeg2video' and video['avg_frame_rate'] == '30000/1001'
          options += ['--rate', '29.97', '--cfr']
        else
          options += ['--rate', '60']
        end
      end

      options += ['--crop-mode', 'conservative'] unless @extra_options.include? 'crop' or
                                                        @extra_options.include? 'crop-mode'
      options
    end

    def get_audio_options(media_info)
      return [] if  @extra_options.include? 'audio'       or
                    @extra_options.include? 'all-audio'   or
                    @extra_options.include? 'first-audio'

      audio_tracks = []

      @audio_selections.each do |selection|
        unless selection[:track].nil?
          index = 0

          media_info['streams'].each do |stream|
            next if stream['codec_type'] != 'audio'

            index += 1

            if index == selection[:track]
              audio_tracks += [{
                :index => index,
                :stream => stream
              }]

              break
            end
          end
        end

        unless selection[:language].nil?
          index = 0

          media_info['streams'].each do |stream|
            next if stream['codec_type'] != 'audio'

            index += 1

            if  selection[:language] == 'all' or
                stream.fetch('tags', {}).fetch('language', '') == selection[:language]
              audio_tracks += [{
                :index => index,
                :stream => stream
              }]
            end
          end
        end

        unless selection[:title].nil?
          index = 0

          media_info['streams'].each do |stream|
            next if stream['codec_type'] != 'audio'

            index += 1

            if stream.fetch('tags', {}).fetch('title', '') =~ /#{selection[:title]}/i
              audio_tracks += [{
                :index => index,
                :stream => stream
              }]
            end
          end
        end
      end

      audio_tracks.uniq!
      return [] if audio_tracks.empty?

      track_list = []
      encoder_list = []
      bitrate_list = []
      mixdown_list = []
      name_list = []

      audio_tracks.each do |audio|
        track_list += [audio[:index].to_s]

        unless @extra_options.include? 'aencoder'
          channels = audio[:stream]['channels'].to_i
          codec_name = audio[:stream]['codec_name']

          case @audio_mode
          when :aac
            if  (codec_name == 'aac' and channels <= 6) or
                (@ac3_surround and codec_name == 'ac3' and channels > 2)
              encoder = 'copy'
              bitrate = ''
              mixdown = ''
            else
              encoder = @aac_encoder

              case channels
              when 1
                bitrate = '80'
                mixdown = 'mono'
              when 2
                bitrate = '128'
                mixdown = 'stereo'
              else
                if @ac3_surround
                  encoder = 'ac3'
                  bitrate = '448'
                else
                  bitrate = '384'
                end

                mixdown = '5point1'
              end
            end
          when :opus
            if codec_name == 'opus'
              encoder = 'copy'
              bitrate = ''
              mixdown = ''
            else
              encoder = 'opus'

              case channels
              when 1
                bitrate = '64'
                mixdown = 'mono'
              when 2
                bitrate = '96'
                mixdown = 'stereo'
              else
                bitrate = '320'
                mixdown = '5point1'
              end
            end
          when :eac3
            if (codec_name =~ /ac3$/) or (codec_name == 'aac' and channels <= 6)
              encoder = 'copy'
              bitrate = ''
              mixdown = ''
            else
              encoder = 'eac3'

              case channels
              when 1
                bitrate = '96'
                mixdown = 'mono'
              when 2
                bitrate = '192'
                mixdown = 'stereo'
              else
                bitrate = '448'
                mixdown = '5point1'
              end
              end
        else
            encoder = ''
            bitrate = ''
            mixdown = ''
          end

          encoder_list += [encoder]
          bitrate_list += [bitrate]
          mixdown_list += [mixdown]
      end

        unless audio_tracks.count == 1 or @extra_options.include? 'aname'
          name_list += audio[:index] == 1 ? [''] : [audio[:stream].fetch('tags', {}).fetch('title', '').gsub(/,/, '","')]
        end
      end

      options = ['--audio', track_list.join(',')]

      unless @extra_options.include? 'aencoder'
        encoder_arg = encoder_list.join(',')
        options += ['--aencoder', encoder_arg] unless encoder_arg.empty?
        bitrate_arg = bitrate_list.join(',')
        options += ['--ab', bitrate_arg] unless bitrate_arg.empty? or @extra_options.include? 'ab'
        mixdown_arg = mixdown_list.join(',')
        options += ['--mixdown', mixdown_arg] unless mixdown_arg.empty? or @extra_options.include? 'mixdown'
      end

      unless audio_tracks.count == 1 or @extra_options.include? 'aname'
        options += ['--aname', name_list.join(',')]
      end

      options
    end

    def get_subtitle_options(media_info)
      return [] if  @extra_options.include? 'subtitle'        or
                    @extra_options.include? 'all-subtitles'   or
                    @extra_options.include? 'first-subtitle'

      options = []

      unless @burn_subtitle.nil?
        subtitle = nil
        index = 0

        media_info['streams'].each do |stream|
          next if stream['codec_type'] != 'subtitle'

          index += 1

          if @burn_subtitle == :auto
            if stream['codec_type'] == 'subtitle' and stream['disposition']['forced'] == 1
              subtitle = stream
              break
            end
          elsif index == @burn_subtitle
            subtitle = stream
            break
          end
        end

        return [] if subtitle.nil?

        options = ['--subtitle', index.to_s]

        if subtitle['codec_name'] == 'hdmv_pgs_subtitle' or subtitle['codec_name'] == 'dvd_subtitle'
          options += ['--subtitle-burned']
        else
          options += ['--subtitle-default']
        end
      end

      unless @subtitle_selections.empty?
        subtitle_tracks = []
        index = 0

        media_info['streams'].each do |stream|
          next if stream['codec_type'] != 'subtitle'

          index += 1

          if stream['disposition']['forced'] == 1
            subtitle_tracks += [{
              :index => index,
              :stream => stream
            }]

            break
          end
        end

        @subtitle_selections.each do |selection|
          unless selection[:track].nil?
            index = 0

            media_info['streams'].each do |stream|
              next if stream['codec_type'] != 'subtitle'

              index += 1

              if index == selection[:track]
                subtitle_tracks += [{
                  :index => index,
                  :stream => stream
                }]

                break
              end
            end
          end

          unless selection[:language].nil?
            index = 0

            media_info['streams'].each do |stream|
              next if stream['codec_type'] != 'subtitle'

              index += 1

              if  selection[:language] == 'all' or
                  stream.fetch('tags', {}).fetch('language', '') == selection[:language]
                subtitle_tracks += [{
                  :index => index,
                  :stream => stream
                }]
              end
            end
          end

          unless selection[:title].nil?
            index = 0

            media_info['streams'].each do |stream|
              next if stream['codec_type'] != 'subtitle'

              index += 1

              if stream.fetch('tags', {}).fetch('title', '') =~ /#{selection[:title]}/i
                subtitle_tracks += [{
                  :index => index,
                  :stream => stream
                }]
              end
            end
          end
        end

        subtitle_tracks.uniq!
        return [] if subtitle_tracks.empty?

        track_list = []
        default = nil
        name_list = []

        subtitle_tracks.each do |subtitle|
          index = subtitle[:index].to_s
          track_list += [index]
          default ||= index if subtitle[:stream]['disposition']['forced'] == 1

          unless @extra_options.include? 'subname'
            name_list += [subtitle[:stream].fetch('tags', {}).fetch('title', '').gsub(/,/, '","')]
          end
        end

        options = ['--subtitle', track_list.join(',')]
        options += ['--subtitle-default', default] unless default.nil?

        unless @extra_options.include? 'subname'
          options += ['--subname', name_list.join(',')]
        end
      end

      options
    end
  end
end

Transcoding::Command.new.run
