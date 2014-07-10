#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'execution'

module Rundeck
  class Job < Base
    attr_reader :id, :uuid, :description, :name, :project, :options, :group, :multipleExecutions

    def initialize definition
      parse_definitions definition
    end

    def options 
      ( @options || {} )
    end

    def executions &block
      get( "/api/1/job/#{id}/executions" )['executions'].map do |x|
        x = Rundeck::Execution.new x 
        yield x if block_given?
      end
    end

    def definition format = 'yaml'
      check_format format
      get "/api/1/job/#{@id}?format=#{format}", {}, false
    end

    def run arguments = {}
      Rundeck::Execution.new( 
        post( "/api/1/job/#{@id}/run", { :argString => generate_job_options( arguments ) } ) 
      )
    end

    private
    def generate_job_options arguments = {}
      job_arguments = ""
      arguments.each_pair { |k,v| job_arguments << "-#{k.to_s} #{v} " } 
      job_arguments
    end

    def parse_definitions definition
      begin 
        @id = definition['id'].first
        @name = definition['name'].first
        @uuid = definition['uuid'].first 
        @description = ( definition['description'].first.empty? ) ? 'no description' : definition['description'].first
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
