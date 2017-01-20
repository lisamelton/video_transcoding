#
# media.rb
#
# Copyright (c) 2013-2017 Don Melton
#

module VideoTranscoding
  class Media
    attr_reader :path

    def initialize(path: nil, title: nil, autocrop: false, extended: true, allow_directory: true)
      fail 'missing path argument' if path.nil?
      @path     = path
      @previews = autocrop ? 10 : 2
      @extended = extended
      @scan     = nil
      @stat     = File.stat(@path)

      if @stat.directory?
        fail UsageError, "not a file: #{@path}" unless allow_directory
        @title = title

        if @title.nil?
          @scan = Media.scan(@path, 0, 2)
        elsif @title < 1
          fail UsageError, "invalid title index: #{@title}"
        end
      else
        fail UsageError, "invalid title index: #{title}" unless title.nil? or title == 1
        @title = 1
      end

      @scan       = Media.scan(@path, @title, @previews) if @scan.nil?
      @first_scan = @scan
      @mp4_scan   = nil
      @summary    = nil
      @info       = nil
    end

    def summary
      if @summary.nil?
        @summary = ''
        @first_scan.each_line { |line| @summary += line if line =~ /^ *\+ (?!(autocrop|support))/ }
      end

      @summary
    end

    def info
      return @info unless @info.nil?
      @info = {}

      if @title.nil?
        if @scan =~ /\+ title ([0-9]+):\r?\n  \+ Main Feature/m
          @title = $1.to_i
        elsif @scan =~ /^\+ title ([0-9]+):/
          @title = $1.to_i
        else
          @title = 1
        end

        @scan = Media.scan(@path, @title, @previews)
      end

      if @scan =~ / libhb: scan thread found ([0-9]+) valid title/
        fail 'multiple titles found' if $1.to_i > 1
      end

      @info[:title]     = @title
      @info[:size]      = @stat.size
      @info[:directory] = @stat.directory?

      unless @scan =~ /^  \+ duration: ([0-9]{2}):([0-9]{2}):([0-9]{2})/
        fail 'media duration not found'
      end

      @info[:duration] = ($1.to_i * 60 * 60) + ($2.to_i * 60) + $3.to_i

      unless @scan =~ / scan: [0-9]+ previews, ([0-9]+)x([0-9]+), ([0-9.]+) fps, autocrop = ([0-9]+)\/([0-9]+)\/([0-9]+)\/([0-9]+), aspect [0-9.]+:[0-9.]+, PAR [0-9]+:[0-9]+/
        fail 'video information not found'
      end

      @info[:width]   = $1.to_i
      @info[:height]  = $2.to_i
      @info[:fps]     = $3.to_f

      if @previews > 2
        @info[:autocrop] = {:top => $4.to_i, :bottom => $5.to_i, :left => $6.to_i, :right => $7.to_i}
      else
        @info[:autocrop] = nil
      end

      return @info unless @extended

      unless @scan =~ /  \+ audio tracks:\r?\n(.*)  \+ subtitle tracks:\r?\n(.*)HandBrake has exited./m
        fail 'audio and subtitle information not found'
      end

      audio             = $1
      subtitle          = $2
      @info[:audio]     = {}
      @info[:subtitle]  = {}

      audio.gsub(/\r/, '').each_line do |line|
        if line =~ /^    \+ ([0-9]+), [^(]+\(([^)]+)\) .*\(([0-9.]+) ch\) .*\(iso639-2: ([a-z]{3})\)/
          track                 = $1.to_i
          track_info            = {}
          track_info[:format]   = $2
          track_info[:channels] = $3.to_f
          track_info[:language] = $4

          if line =~ /([0-9]+)bps/
            track_info[:bps] = $1.to_i
          else
            track_info[:bps] = nil
          end

          @info[:audio][track] = track_info
        end
      end

      subtitle.gsub(/\r/, '').each_line do |line|
        if line =~ /^    \+ ([0-9]+), .*\(iso639-2: ([a-z]{3})\) \((Text|Bitmap)\)\(([^)]+)\)/
          track                   = $1.to_i
          track_info              = {}
          track_info[:language]   = $2
          track_info[:format]     = $3
          track_info[:encoding]   = $4
          @info[:subtitle][track] = track_info
        end
      end

      @info[:h264]    = false
      @info[:hevc]    = false
      @info[:mpeg2]   = false
      audio_track     = 0
      subtitle_track  = 0

      @scan.each_line do |line|
        if line =~ /[ ]+Stream #0[.:]([0-9]+)[^ ]*: (Video|Audio|Subtitle): (.*)/
          stream      = $1.to_i
          type        = $2
          attributes  = $3

          case type
          when 'Video'
            unless @info.has_key? :stream
              @info[:stream] = stream

              if attributes =~ /^h264/
                @info[:h264] = true
              elsif attributes =~ /^hevc/
                @info[:hevc] = true
              elsif attributes =~ /^mpeg2video/
                @info[:mpeg2] = true
              end
            end
          when 'Audio'
            audio_track += 1

            if @info[:audio].has_key? audio_track
              track_info = @info[:audio][audio_track]
              track_info[:stream] = stream

              if @scan =~ /[ ]+Stream #0[.:]#{stream}[^ ]*: Audio: [^\n]+(?:\n[^\n]+)?\(default\)/m
                track_info[:default] = true
              else
                track_info[:default] = false
              end

              if @scan =~ /[ ]+Stream #0[.:]#{stream}[^ ]*: Audio: [^\n]+\n(?:[^\n]+\n)?[ ]+Metadata:\r?\n^[ ]+title[ ]+: ([^\r\n]+)/m
                track_info[:name] = $1
              else
                track_info[:name] = nil
              end
            end
          when 'Subtitle'
            subtitle_track += 1

            if @info[:subtitle].has_key? subtitle_track
              track_info = @info[:subtitle][subtitle_track]
              track_info[:stream] = stream

              if attributes =~ /\(default\)/
                track_info[:default] = true
              else
                track_info[:default] = false
              end

              if attributes =~ /\(forced\)/
                track_info[:forced] = true
              else
                track_info[:forced] = false
              end

              if @scan =~ /[ ]+Stream #0[.:]#{stream}[^ ]*: Subtitle: [^\n]+\n(?:[^\n]+\n)?[ ]+Metadata:\r?\n^[ ]+title[ ]+: ([^\r\n]+)/m
                track_info[:name] = $1
              else
                track_info[:name] = nil
              end
            end
          end
        end
      end

      @info[:bd]  = false
      @info[:dvd] = false

      if @scan =~ / scan: (BD|DVD) has [0-9]+ title/
        @info[$1.downcase.to_sym] = true
        @info[:mpeg2] = true if @info[:dvd]
      end

      if @scan =~ /Input #0, matroska/
        @info[:mkv] = true
      else
        @info[:mkv] = false
      end

      if @scan =~ /Input #0, mov,mp4/
        @info[:mp4] = true
      else
        @info[:mp4] = false
      end

      if @info[:mp4]
        @mp4_scan = Media.scan_mp4(@path)
        types     = []
        flags     = []
        names     = []

        @mp4_scan.each_line do |line|
          if line =~ /^[ ]+type[ ]+=[ ]+(.*)$/
            types << $1
          elsif line =~ /^[ ]+enabled[ ]+=[ ]+(.*)$/
            if $1 == 'true'
              flags << true
            else
              flags << false
            end
          elsif line =~ /^[ ]+userDataName[ ]+=[ ]+(.*)$/
            if $1 == '<absent>'
              names << nil
            else
              names << $1
            end
          end
        end

        index           = 0
        audio_track     = 0
        subtitle_track  = 0

        types.each do |type|
          case type
          when 'audio'
            audio_track += 1

            if @info[:audio].has_key? audio_track
              track_info = @info[:audio][audio_track]
              track_info[:default] = flags[index]
              track_info[:name] = names[index]
            end
          when '(sbtl)', '(subp)', 'text'
            subtitle_track += 1

            if @info[:subtitle].has_key? subtitle_track
              track_info = @info[:subtitle][subtitle_track]
              track_info[:default] = flags[index]
              track_info[:forced] = flags[index]
              track_info[:name] = names[index]
            end
          end

          index += 1
        end

        if subtitle_track > 0 and @scan =~ /[ ]+Chapter #0[.:]0: start /
          @info[:subtitle].delete subtitle_track
        end
      end

      @info
    end

    def self.scan(path, title, previews)
      output = ''
      label = title == 0 ? 'media' : "media title #{title}"
      Console.info "Scanning #{label} with HandBrakeCLI..."
      last_seconds = Time.now.tv_sec

      begin
        IO.popen([
          HandBrake.command_name,
          "--title=#{title}",
          '--scan',
          "--previews=#{previews}:0",
          "--input=#{path}"
        ], :err=>[:child, :out]) do |io|
          io.each do |line|
            seconds = Time.now.tv_sec

            if seconds - last_seconds >= 3
              Console.warn '...'
              last_seconds = seconds
            end

            line.encode! 'UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''
            Console.debug line
            output += line
          end
        end
      rescue SystemCallError => e
        raise "scanning #{label} failed: #{e}"
      end

      fail "scanning #{label} failed" unless $CHILD_STATUS.exitstatus == 0
      output
    end

    def self.scan_mp4(path)
      output = ''
      Console.info 'Scanning with mp4track...'

      begin
        IO.popen([
          MP4track.command_name,
          '--list',
          path
        ], :err=>[:child, :out]) { |io| output = io.read }
      rescue SystemCallError => e
        raise "scanning failed: #{e}"
      end

      Console.debug output
      fail 'scanning failed' unless $CHILD_STATUS.exitstatus == 0
      output
    end
  end
end
