#
# handbrake.rb
#
# Copyright (c) 2013-2016 Don Melton
#

module VideoTranscoding
  module HandBrake
    extend self

    COMMAND_NAME = 'HandBrakeCLI'

    def setup
      Tool.provide(COMMAND_NAME, ['--preset-list']) do |output, status, _|
        fail "#{COMMAND_NAME} failed during execution" unless status == 0

        if output =~ /^HandBrake ([^ ]+)/
          version = $1
          Console.info "#{$MATCH} found..."

          unless  (version =~ /^([0-9]+)\.([0-9]+)/ and (($1.to_i * 100) + $2.to_i) >= 10) or
                  (version =~ /^svn([0-9]+)/ and $1.to_i >= 6536)
            fail "#{COMMAND_NAME} version 0.10.0 or later required"
          end
        end
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end

    def aac_encoder
      properties = Tool.properties(COMMAND_NAME)
      return properties[:aac_encoder] if properties.has_key? :aac_encoder
      output = ''

      begin
        IO.popen([Tool.use(COMMAND_NAME), '--help'], :err=>[:child, :out]) { |io| output = io.read }
      rescue SystemCallError => e
        raise "#{COMMAND_NAME} AAC encoder unknown: #{e}"
      end

      fail "#{COMMAND_NAME} failed during execution" unless $CHILD_STATUS.exitstatus == 0

      if output =~ /ca_aac/
        properties[:aac_encoder] = 'ca_aac'
      else
        properties[:aac_encoder] = 'av_aac'
      end
    end
  end
end
