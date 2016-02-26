#
# mplayer.rb
#
# Copyright (c) 2013-2016 Don Melton
#

module VideoTranscoding
  module MPlayer
    extend self

    COMMAND_NAME = 'mplayer'

    def setup
      Tool.provide(COMMAND_NAME, ['-version']) do |output, _, _|
        unless output =~ /^MPlayer [^ ]+/
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
