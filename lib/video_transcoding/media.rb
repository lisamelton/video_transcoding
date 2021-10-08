#
# media.rb
#
# Copyright (c) 2013-2020 Don Melton
#
require 'English'
require 'json'

module VideoTranscoding
  class Media
    attr_reader :path, :info

    def initialize(path: nil, title: 0, autocrop: false, extended: true, allow_directory: true)
      raise 'missing path argument' if path.nil?

      @path     = path
      # The number of preview images HandBrake will generate
      @previews = autocrop ? 10 : 2
      @extended = extended
      @stat     = File.stat(@path)
      @title    = title || 0
      @summary  = nil

      raise UsageError, "not a file (directory processing disabled): #{@path}" if @stat.directory? && !allow_directory

      @info = Media.scan(@path, @title, @previews)
    end

    def self.language_code(language)
      mapping = {
        'alb' => 'sqi',
        'arm' => 'hye',
        'baq' => 'eus',
        'bur' => 'mya',
        'chi' => 'zho',
        'cze' => 'ces',
        'dut' => 'nld',
        'fre' => 'fra',
        'geo' => 'kat',
        'ger' => 'deu',
        'gre' => 'ell',
        'ice' => 'isl',
        'mac' => 'mkd',
        'mao' => 'mri',
        'per' => 'fas',
        'rum' => 'ron',
        'slo' => 'slk',
        'tib' => 'bod',
        'wel' => 'cym'
      }

      mapping.key?(language) ? mapping[language] : language
    end

    def self.run_handbrake(path, title_to_scan, previews)
      # if title_to_scan == 0, scan all titles, rely on HandBrake to
      # choose the MainFeature
      label = title_to_scan.zero? ? 'media' : "media title #{title_to_scan}"
      Console.info "Scanning #{label} with HandBrakeCLI..."

      hb_raw = ''
      begin
        IO.popen([
                   'HandBrakeCLI',
                   "--title=#{title_to_scan}",
                   '--scan',
                   '--json',
                   "--previews=#{previews}:0",
                   "--input=#{path}"
                 ], err: '/dev/null') do |io|
          hb_raw = io.read
          hb_raw = fixup_hb_output(hb_raw)
          Console.debug hb_raw
        end
      rescue SystemCallError => e
        raise "scanning #{label} failed: #{e}"
      end

      # If no video stream is present, HandBrake will have exited
      # with an error status.
      raise "scanning #{label} failed (exit: #{$CHILD_STATUS.exitstatus}" unless $CHILD_STATUS.exitstatus.zero?

      hb_raw
    end

    def self.scan(path, title_to_scan, previews)
      hb_out = run_handbrake(path, title_to_scan, previews)

      # The HandBrakeCLI output has several JSON objects
      # Version (of HandBrake), Progress (several times), JSON Title Set
      # We just need the Title Set
      hb_json = hb_out.partition('JSON Title Set: ')[2]
      raise 'scanning with HandBrake failed: no JSON output' if hb_json == ''

      # Now parse the JSON
      root = JSON.parse(hb_json)

      # Select the correct title
      title = {}
      if title_to_scan.zero?
        if (root['MainFeature']).zero?
          Console.debug 'HandBrake could not identify the MainFeature, using first title'
          title = root['TitleList'][0]
        else
          Console.debug "MainFeature is title #{root['MainFeature']}"
          title = root['TitleList'].select { |t| t['Index'] == root['MainFeature'] }
          raise "Couldn't find title that was identified as MainFeature" if title.empty?

          # .select returns an array, but we just want the first entry
          title = title[0]
        end
      else
        # A specific title was specified on the command line,
        # so it should be the only one in the TitleList
        raise "Failed to find title #{title_to_scan}" if root['TitleList'].empty?

        title = root['TitleList'][0]
      end

      # Get File info
      stat = File.stat(path)

      info = {
        title: title['Index'],
        size: stat.size,
        directory: stat.directory?,
        mkv: title.key?('Container') ? title['Container'].match?(/matroska|mkv/i) : false,
        mp4: title.key?('Container') ? title['Container'].match?(/mp4/i) : false,
        width: title['Geometry']['Width'],
        height: title['Geometry']['Height'],
        fps: (title['FrameRate']['Num'].to_f / title['FrameRate']['Den']).round(3),
        h264: title['VideoCodec'].match?(/h264/i),
        hevc: title['VideoCodec'].match?(/hevc|h265/i),
        mpeg2: title['VideoCodec'].match?(/mpeg2/i),
        # TODO: HandBrake JSON doesn't give the stream numbers
        # might be in 
        #   hb_title_s.video_id
        #   hb_audio_s.id
        #   hb_subtitle_s.id
        stream: 0
      }

      # Convert duration to seconds
      duration = title['Duration']
      info[:duration] = duration['Hours'] * 60 * 60 + duration['Minutes'] * 60 + duration['Seconds']

      # Handle autocrop (previews)
      info[:autocrop] = if previews > 2 && title.key?('Crop')
                          {
                            top: title['Crop'][0],
                            bottom: title['Crop'][1],
                            left: title['Crop'][2],
                            right: title['Crop'][3]
                          }
                        end

      # Collect audio tracks
      info[:audio] = {}
      title['AudioList'].each_with_index do |track, i|
        info[:audio][i + 1] = {
          stream: i,
          language: language_code(track['LanguageCode']),
          format: track['CodecName'],
          channels: track['ChannelCount'].to_i,
          bps: track['BitRate'],
          default: track['Attributes']['Default'],
          name: track['Description']
        }
      end

      # Collect subtitle tracks
      info[:subtitle] = {}
      title['SubtitleList'].each_with_index do |track, i|
        info[:subtitle][i + 1] = {
          stream: i,
          language: language_code(track['LanguageCode']),
          format: track['Format'],
          encoding: track['SourceName'],
          default: track['Attributes']['Default'],
          forced: track['Attributes']['Forced'],
          name: track['Language']
        }
      end

      info
    end

    def self.fixup_hb_output(hb_raw)
      hb_raw.encode 'UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''
    end

    # Gets a summary from HandBrakeCLI,
    # using the raw (not JSON) output
    def summary
      if @summary.nil?
        IO.popen([
                   'HandBrakeCLI',
                   "--title=#{@title}",
                   '--scan',
                   "--input=#{@path}"
                 ], err: %i[child out]) do |io|
          @summary = io.readlines.select do |line|
            # HandBrakeCLI gives a summary where each line begins with
            # a '+' character.
            fixup_hb_output(line).match(/^\s*\+ (?!(autocrop|support))/)
          end.join('')
        end
      end

      @summary
    end
  end
end
