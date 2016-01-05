#
# ffmpeg.rb
#
# Copyright (c) 2013-2016 Don Melton
#

module VideoTranscoding
  module FFmpeg
    extend self

    COMMAND_NAME = 'ffmpeg'

    def setup
      Tool.provide(COMMAND_NAME, ['-version']) do |output, status, properties|
        fail "#{COMMAND_NAME} failed during execution" unless status == 0

        unless output =~ /^ffmpeg version ([0-9.]+)/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        version = $1
        Console.info "#{$MATCH} found..."

        unless version =~ /^([0-9]+)\.([0-9]+)/ and (($1.to_i * 100) + $2.to_i) >= 205
          fail "#{COMMAND_NAME} version 2.5.0 or later required"
        end

        if output =~ /--enable-libfdk-aac/
          properties[:aac_encoder] = 'libfdk_aac'
        elsif output =~ /--enable-libfaac/
          properties[:aac_encoder] = 'libfaac'
        else
          properties[:aac_encoder] = 'aac'
        end
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end

    def aac_encoder
      Tool.properties(COMMAND_NAME)[:aac_encoder]
    end
  end
end
