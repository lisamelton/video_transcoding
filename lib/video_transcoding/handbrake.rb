#
# handbrake.rb
#
# Copyright (c) 2013-2020 Don Melton
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

    def aac_encoder
      properties = Tool.properties(COMMAND_NAME)

      unless properties.has_key? :aac_encoder
        if help_text =~ /ca_aac/
          properties[:aac_encoder] = 'ca_aac'
        else
          properties[:aac_encoder] = 'av_aac'
        end
      end

      properties[:aac_encoder]
    end

    private

    def help_text
      properties = Tool.properties(COMMAND_NAME)

      unless properties.has_key? :help_text
        properties[:help_text] = ''

        begin
          IO.popen([Tool.use(COMMAND_NAME), '--help'], :err=>[:child, :out]) do |io|
            properties[:help_text] = io.read
          end
        rescue SystemCallError => e
          raise "#{COMMAND_NAME} help text unavailable: #{e}"
        end

        fail "#{COMMAND_NAME} failed during execution" unless $CHILD_STATUS.exitstatus == 0
      end

      properties[:help_text]
    end
  end
end
