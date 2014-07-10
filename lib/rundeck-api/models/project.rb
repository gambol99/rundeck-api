#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'job'
require 'utils'

module Rundeck
  class Project < Base 
    attr_reader :name, :description

    def initialize definition
      parse_definition definition
    end
    
    def jobs &block
      get( "/api/1/jobs/export?project=#{@name}" )['job'].map do |x|
        data = Rundeck::Job.new x          
        yield data if block_given?
        data
      end
    end

    def job name 
      raise "the job: #{name} does not exist in this project" unless job? name 
      x = jobs.select { |x| x.name == name }.first 
    end

    def job? name 
      list.include? name 
    end

    def list
      jobs.map { |x| x.name }
    end

    def export format = 'yaml'
      check_format format
      get( "/api/1/jobs/export?project=#{name}&format=#{format}", {}, false )
    end

    def import job, options = {}
      required [ :format, :dupe, :remove ], options
      check_format options[:format]
      post( "/api/1/jobs/import", {
        :project => @name,
        :format  => options[:format],
        :dupeOption => options[:dupe],
        :uuidOption => options[:uuid],
        :xmlBatch => job
      } )
    end

    private 
    def parse_definition definition
      @name = definition['name'].first
      @description = definition['description'].first
    end
  end
end
