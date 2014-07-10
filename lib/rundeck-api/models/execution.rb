#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'output'

module Rundeck
  class Execution < Base
    attr_reader :success, :apiversion, :id, :href, :user, :project, :started, :status

    def initialize definition
      parse_definition definition
    end

    def finished?
      status =~ /(finished|failed|error|succeeded)/
    end

    def running?
      execution['status'] =~ /running/
    end

    def kill 
      raise ArgumentError, "the execution: #{id} is not running at the moment, cannot abort" unless running?
      execution_abort
    end

    def waitfor interval = 0.5, timeout = 120, &block
      while !finished?
        yield if block_given?
        sleep interval
      end
      yield self if block_given?
    end

    def output 
      raise ArgumentError, "the execution has not yet finished, please wait until the job has ended" unless finished?
      Rundeck::Output.format( execution_output_format( execution_output ) )
    end

    def tail interval = 0.5, &block
      raise ArgumentError, "the execution has already finished, you can only tail a running task" unless running?
      offset = 0
      while running?
        response       = execution_output offset
        current_offset = Rundeck::Output.offset( response )
        if current_offset == offset
          sleep interval
        else 
          offset = current_offset
          yield Rundeck::Output.format( response )
        end
      end
    end

    private
    def execution
      response = get( "/api/1/execution/#{@id}" )
      response['executions'].first['execution'].first
    end

    def execution_abort
      post( "api/1/execution/#{id}/abort" )
    end

    def execution_output offset = 0
      get( "/api/5/execution/#{@id}/output?offset=#{offset}" )
    end

    def execution_output_format response 
      Rundeck::Output.format( response ) 
    end

    def parse_definition definition
      @success    = definition['success']
      @apiversion = definition['apiversion']
      execution   = definition['executions'].first['execution'].first
      @id         = execution['id']
      @href       = execution['href']
      @user       = execution['user']
      @status     = execution['status']
      @started    = execution['date-started'].first['unixtime']
    end
  end
end 
