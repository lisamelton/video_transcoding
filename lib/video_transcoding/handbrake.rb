#
# handbrake.rb
#
# Copyright (c) 2013-2017 Don Melton
#

module VideoTranscoding
  module HandBrake
    extend self

    COMMAND_NAME = 'HandBrakeCLI'

    def setup
      Tool.provide(COMMAND_NAME, ['--preset-list']) do |output, status, _|
        fail "#{COMMAND_NAME} failed during execution" unless status == 0

        if output =~ /^HandBrake ([^h][^ ]+)/
          version = $1
          Console.info "#{$MATCH} found..."

          unless  (version =~ /^([0-9]+)\.([0-9]+)/ and (($1.to_i * 100) + $2.to_i) >= 10) or
                  (version =~ /^svn([0-9]+)/ and $1.to_i >= 6536)
            fail "#{COMMAND_NAME} version 0.10.0 or later required"
          end
        end
      end

      begin
        IO.popen([Tool.use(COMMAND_NAME), '--version'], :err=>[:child, :out]) do |io|
          if io.read =~ /^HandBrake ([^h][^ ]+)/
            Console.info "#{$MATCH.strip} found..."
          end
        end
      rescue SystemCallError => e
        raise "#{COMMAND_NAME} failed during execution: #{e}"
      end
    end

    def command_name
      Tool.use(COMMAND_NAME)
    end

    def auto_anamorphic
      properties = Tool.properties(COMMAND_NAME)

      unless properties.has_key? :auto_anamorphic
        if help_text =~ /auto-anamorphic/
          properties[:auto_anamorphic] = 'auto-anamorphic'
        else
          properties[:auto_anamorphic] = 'strict-anamorphic'
        end
      end

      properties[:auto_anamorphic]
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
