#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'rundeck-cli/' )
require 'models'
module Rundeck
  module API
    ROOT = File.expand_path File.dirname __FILE__

    require "#{ROOT}/rundeck-cli/version"

    autoload :Version,  "#{ROOT}/rundeck-cli/version"
    autoload :Session,  "#{ROOT}/rundeck-cli/session"
    autoload :Models,   "#{ROOT}/rundeck-cli/models"
    autoload :Utils,    "#{ROOT}/rundeck-cli/utils"

    def self.version
      Rundeck::VERSION
    end 

    def self.new options
      session = Rundeck::API::Session.new options
      Rundeck::Models::Projects.new session
    end
  end
end
