#
# console.rb
#
# Copyright (c) 2025 Lisa Melton
#

module VideoTranscoding
  module Console
    OFF   = 0
    ERROR = 1
    WARN  = 2
    INFO  = 3
    DEBUG = 4

    def self.included(base)
      fail "#{self} singleton can't be included by #{base}"
    end

    def self.extended(base)
      fail "#{self} singleton can't be extended by #{base}" unless base.class == Module
      @speaker = ->(msg) { Kernel.warn msg }
      @volume = WARN
    end

    extend self

    attr_accessor :speaker
    attr_accessor :volume

    def error(msg)
      @speaker.call msg unless @speaker.nil? or @volume < ERROR
    end

    def warn(msg)
      @speaker.call msg unless @speaker.nil? or @volume < WARN
    end

    def info(msg)
      @speaker.call msg unless @speaker.nil? or @volume < INFO
    end

    def debug(msg)
      @speaker.call msg unless @speaker.nil? or @volume < DEBUG
    end
  end
end
