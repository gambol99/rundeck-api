#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'rundeck-api/' )
require 'models'
module Rundeck
  module API
    ROOT = File.expand_path File.dirname __FILE__

    require "#{ROOT}/rundeck-api/version"

    autoload :Version,  "#{ROOT}/rundeck-api/version"
    autoload :Session,  "#{ROOT}/rundeck-api/session"
    autoload :Models,   "#{ROOT}/rundeck-api/models"
    autoload :Utils,    "#{ROOT}/rundeck-api/utils"

    def self.version
      Rundeck::VERSION
    end 

    def self.new options
      session = Rundeck::API::Session.new options
      Rundeck::Models::Projects.new session
    end
  end
end
