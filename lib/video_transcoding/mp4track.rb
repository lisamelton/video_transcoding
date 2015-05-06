#
# mp4track.rb
#
# Copyright (c) 2013-2015 Don Melton
#

module VideoTranscoding
  module MP4track
    extend self

    COMMAND_NAME = 'mp4track'

    def setup
      Tool.provide(COMMAND_NAME, ['--version']) do |output, status, _|
        fail "#{COMMAND_NAME} failed during execution" unless status == 0

        unless output =~ /^mp4track - MP4v2 ([0-9.]+)/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        version = $1
        Console.info "#{$MATCH} found..."

        unless version =~ /^([0-9]+)\.([0-9]+)/ and (($1.to_i * 100) + $2.to_i) >= 200
          fail "#{COMMAND_NAME} version 2.0.0 or later required"
        end
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end
  end
end
