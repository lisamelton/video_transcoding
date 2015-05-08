#
# mplayer.rb
#
# Copyright (c) 2013-2015 Don Melton
#

module VideoTranscoding
  module MPlayer
    extend self

    COMMAND_NAME = 'mplayer'

    def setup
      Tool.provide(COMMAND_NAME, ['-version']) do |output, _, _|
        unless output =~ /^MPlayer .*-([0-9]+)\.([0-9]+)\.[0-9]+ /
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        major_version = $1.to_i
        minor_version = $2.to_i
        Console.info "#{$MATCH} found..."

        unless ((major_version * 100) + minor_version) >= 402
          fail "#{COMMAND_NAME} version 4.2 or later required"
        end
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end
  end
end
