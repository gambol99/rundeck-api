#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-22 18:10:39 +0100 (Tue, 22 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
require 'yaml'

module Rundeck
  class CLI
    include Rundeck::Utils
    include Rundeck::Logging

    protected
    def options data = {}
      @options ||= data
    end

    def settings filename = nil
      @config ||= load_configuration
    end

    def load_configuration filename = "#{ENV['HOME']}/.rundeck.yaml"
      validate_file filename rescue "the configuration file: #{filename} is invalid, please check"
      YAML.load(File.read(filename))
    end
  end
end
