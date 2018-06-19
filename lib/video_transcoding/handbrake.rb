#
# handbrake.rb
#
# Copyright (c) 2013-2018 Don Melton
#

module VideoTranscoding
  module HandBrake
    extend self

    COMMAND_NAME = 'HandBrakeCLI'

    def setup
      Tool.provide(COMMAND_NAME, ['--version']) do |output, status, _|
        fail "#{COMMAND_NAME} version 1.0.0 or later required" unless status == 0

        unless output =~ /^HandBrake ([^h][^ ]+)/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        Console.info "#{$MATCH.strip} found..."
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end
  end
end
