#
# mkvpropedit.rb
#
# Copyright (c) 2013-2019 Don Melton
#

module VideoTranscoding
  module MKVpropedit
    extend self

    COMMAND_NAME = 'mkvpropedit'

    def setup
      Tool.provide(COMMAND_NAME, ['--version']) do |output, status, _|
        fail "#{COMMAND_NAME} failed during execution" unless status == 0

        unless output =~ /^mkvpropedit v([0-9.]+)/
          Console.debug output
          fail "#{COMMAND_NAME} version unknown"
        end

        version = $1
        Console.info "#{$MATCH} found..."

        unless version =~ /^([0-9]+)\.([0-9]+)/ and (($1.to_i * 100) + $2.to_i) >= 700
          fail "#{COMMAND_NAME} version 7.0.0 or later required"
        end
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end
  end
end
