#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'output'

module Rundeck
  module Models
    class Execution
      attr_reader :success, :apiversion, :id, :href, :user, :project, :started 

      def initialize session, definition
        @session = session
        parse_definition definition
      end

      def finished?
        status =~ /(finished|failed|error|succeeded)/
      end

      def running?
        execution['status'] =~ /running/
      end

      def status
        execution['status']
      end

      def waitfor interval = 0.5, timeout = 120, &block
        while !finished?
          yield if block_given?
          sleep interval
        end
        yield self if block_given?
      end

      def output
        raise ArgumentError, "the job is still running, you have to wait until finished" if running?
        output = Rundeck::Models::Output.format( @session.get( "/api/5/execution/#{@id}/output" ) )
      end

      private
      def execution 
        response = @session.get( "/api/1/execution/#{@id}" )
        return response['executions'].first['execution'].first if response['success'] == 'true'
        raise Exception, 'failed to get the status for this execution'
      end

      def parse_definition definition
        @success    = definition['success']
        @apiversion = definition['apiversion']
        execution   = definition['executions'].first['execution'].first
        @id         = execution['id']
        @ref        = execution['href']
        @user       = execution['user']
        @started    = execution['date-started'].first['unixtime']
      end
    end
  end
end 