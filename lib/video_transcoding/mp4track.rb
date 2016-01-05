#
# mp4track.rb
#
# Copyright (c) 2013-2016 Don Melton
#

module VideoTranscoding
  module MP4track
    extend self

    COMMAND_NAME = 'mp4track'

    def setup
      Tool.provide(COMMAND_NAME, ['--version']) do |output, status, _|
        fail "#{COMMAND_NAME} failed during execution" unless status == 0

        unless output =~ /^mp4track - MP4v2 .*/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        Console.info "#{$MATCH} found..."
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end
  end
end
