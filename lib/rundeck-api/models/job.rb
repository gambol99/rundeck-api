#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'execution'

module Rundeck
  module Models
    class Job

      attr_reader :id, :uuid, :description, :name, :project, :options

      def initialize session, definition
        @session = session
        parse_definitions definition
      end

      def running?

      end

      def history

      end

      def options 
        ( @options || {} )
      end

      def run arguments = {}
        job_arguments = ""
        if !@options.empty?
          arguments.each_pair do |k,v| 
            job_arguments << "-#{k.to_s} #{v} "
          end
        end
        Rundeck::Models::Execution.new( @session, 
          @session.post( "/api/1/job/#{@id}/run", { :argString => job_arguments } ) 
        )
      end

      private
      def parse_definitions definition
        begin 
          %w(id uuid description name loglevel).each { |x| instance_variable_set("@#{x}", definition[x].first ) }
          @project = definition['context'].first['project']
          if definition['context'].first.has_key? 'options'
            @options = definition['context'].first['options'].first['option']
          else
            @options = {}
          end
        rescue Exception => e 
          raise Exception, "unable to parse the job definition: #{e.message}"
        end
      end
    end
  end
end
