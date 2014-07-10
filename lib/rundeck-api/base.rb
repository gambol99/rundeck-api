#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-09 16:03:01 +0100 (Wed, 09 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
require 'utils'
require 'logging'
require 'adapter'

module Rundeck
  class Base
    include Rundeck::Utils
    include Rundeck::Adapter
    include Rundeck::Logging

    class Settings
      def initialize options 
        @@config = options
      end
      def self.[](key)
        return @@config[key] if @@config[key]
        return @@config[key.to_s] if @@config[key.to_s]
        nil
      end
    end

    def set_configuration options
      options = validate_options options
      options = set_configuration_defaults options
      @@config ||= Settings.new options
      self
    end

    def projects 
      Rundeck::Projects.new 
    end

    def project name 
      projects.project name 
    end

    protected
    def settings
      Settings
    end

    private
    def set_configuration_defaults options 
      [ :verbose, :debug, :colors ].each { |x| options[x] ||= false }
      options[:accepts] ||= 'application/xml'
      options
    end

    def validate_options options 
      required %w(rundeck api_token), options
      raise ArgumentError, "the rundeck: #{options['rundeck']} is an invalid url" unless valid_url? options['rundeck']
      options
    end
  end
end
