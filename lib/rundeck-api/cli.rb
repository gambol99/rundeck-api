#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-22 18:10:39 +0100 (Tue, 22 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
require 'yaml'
require 'optionscrapper'

module Rundeck
  class CLI
    include Rundeck::Utils
    include Rundeck::Logging

    protected
    def options data = {}
      @options ||= data
    end

    def settings filename = nil
      @config ||= configuration filename
    end

    def configuration filename 
      filename ||= "#{ENV['HOME']}/.rundeck.yaml"
      validate_file filename
      validate_configuration YAML.load(File.read(filename))
    end

    def validate_configuration config = {} 
      config.each_pair do |name,args|
        required %(url api_token project), args 
        raise ArgumentError, "the url: #{args['url']} in rundeck entry: #{name} is invalid" unless valid_url? args['url']
      end
      if config['default'] and !config[config['default']]
        raise ArgumentError, "the default rundeck: #{config['default']} does not exist" 
      end
      config
    end
  end
end
