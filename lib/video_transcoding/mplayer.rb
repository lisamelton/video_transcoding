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
        unless output =~ /^MPlayer ([0-9.]+)/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        version = $1
        Console.info "#{$MATCH} found..."

        unless version =~ /^([0-9]+)\.([0-9]+)/ and (($1.to_i * 100) + $2.to_i) >= 101
          fail "#{COMMAND_NAME} version 1.1 or later required"
        end
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end
  end
end
