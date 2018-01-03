#
# tool.rb
#
# Copyright (c) 2013-2018 Don Melton
#

module VideoTranscoding
  class Tool
    attr_reader :properties

    def self.provide(command_name, test_args, &test_block)
      fail "#{command_name} already provided" if @@tools.has_key? command_name
      @@tools[command_name] = Tool.new(command_name, test_args, &test_block)
    end

    def self.use(command_name)
      fail "#{command_name} not provided" unless @@tools.has_key? command_name
      @@tools[command_name].prepare
      command_name
    end

    def self.properties(command_name)
      fail "#{command_name} not provided" unless @@tools.has_key? command_name
      @@tools[command_name].prepare
      @@tools[command_name].properties
    end

    def prepare
      return if @ready
      output = ''

      begin
        IO.popen([@command_name] + @test_args, :err=>[:child, :out]) { |io| output = io.read }
      rescue Errno::ENOENT
        raise "#{@command_name} not available"
      end

      @test_block.call output, $CHILD_STATUS.exitstatus, @properties
      @ready = true
    end

    private

    @@tools = {}

    def initialize(command_name, test_args, &test_block)
      @command_name, @test_args, @test_block = command_name, test_args, test_block
      @properties = {}
      @ready = false
    end
  end
end
