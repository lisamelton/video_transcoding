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

        unless output =~ /^ffmpeg version [^ ]+/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        Console.info "#{$MATCH} found..."

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
