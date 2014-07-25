#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-22 18:10:39 +0100 (Tue, 22 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
require 'yaml'
require 'optionscrapper'
require 'pp'

module Rundeck
  class CLI
    include Rundeck::Utils
    include Rundeck::Logging

    protected
    def options data = default_options
      @options ||= data
    end

    def default_options
      {
        :colors => true
      }
    end

    def settings filename = nil
      @config ||= configuration filename
    end

    def decker
      @decker ||= Rundeck::API.new select_rundeck
    end

    def project
      @project ||= decker.project select_rundeck['project']
    end

    def rundecks
      settings['rundecks']
    end

    def rundeck? name
      rundecks.keys.include? name
    end

    def default_deck
      settings['default']
    end

    def rundeck
      select_rundeck
    end

    def select_rundeck
      unless @rundeck
        if options[:rundeck]
          raise ArgumentError, "the rundeck: #{options[:rundeck]} does not exist in configuration" unless rundeck? options[:rundeck]
          @rundeck = rundecks[options[:rundeck]]
        else
          if rundecks.size > 1 and !default_deck
            raise ArgumentError, "you have multiple rundecks in configuration, but no default and nothing selected"
          end
          @rundeck = rundecks[default_deck]
        end
      end
      @rundeck
    end

    def configuration filename
      filename ||= "#{ENV['HOME']}/.rundeck.yaml"
      validate_file filename
      validate_configuration YAML.load(File.read(filename))
    end

    def fail message
      parser.usage message
    end

    def validate_configuration config = {}
      raise ArgumentError, "you have not defined any rundecks in your configuration" unless config['rundecks']
      decks = config['rundecks']
      decks.keys.each do |name|
        rundeck_config = decks[name]
        required %w(rundeck api_token project), rundeck_config
        raise ArgumentError, "the url: #{args['rundeck']} in rundeck entry: #{name} is invalid" unless valid_url? rundeck_config['rundeck']
      end
      if config['default'] and !decks[config['default']]
        raise ArgumentError, "the default rundeck: #{config['default']} does not exist in configuration"
      end
      config
    end
  end
end
