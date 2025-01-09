#
# cli.rb
#
# Copyright (c) 2025 Lisa Melton
#

require 'optparse'
require 'video_transcoding'

module VideoTranscoding
  module CLI
    def run
      begin
        OptionParser.new do |opts|
          define_options opts
          opts.on('-v', '--verbose')  { Console.volume += 1 }
          opts.on('-q', '--quiet')    { Console.volume -= 1 }

          opts.on '-h', '--help' do
            puts usage
            exit
          end

          opts.on '--version' do
            puts about
            exit
          end
        end.parse!
      rescue OptionParser::ParseError => e
        raise UsageError, e
      end

      Console.info about
      configure
      fail UsageError, 'missing argument' if ARGV.empty?
      ARGV.each { |arg| process_input arg }
      complete if self.respond_to? :complete
      Console.info 'Done.'
      terminate if self.respond_to? :terminate
      exit
    rescue UsageError => e
      warn "#{$PROGRAM_NAME}: #{e}\nTry `#{$PROGRAM_NAME} --help` for more information."
      exit false
    rescue StandardError => e
      Console.error "#{$PROGRAM_NAME}: #{e}"
      exit(-1)
    rescue SignalException
      terminate if self.respond_to? :terminate
      puts
      exit(-1)
    end
  end
end
