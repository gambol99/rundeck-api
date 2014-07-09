#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'rundeck-api/' )
require 'models'
require 'config'

module Rundeck
  class API
    include Rundeck::Config
    ROOT = File.expand_path File.dirname __FILE__
    require "#{ROOT}/rundeck-api/version"

    def self.version
      Rundeck::VERSION
    end 

    def self.new options 
      Config.config options
      Rundeck::Models::Projects.new 
    end
  end
end
