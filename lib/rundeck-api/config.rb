#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-09 16:03:01 +0100 (Wed, 09 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
module Rundeck
  module Config
    include Rundeck::Utils
    
    def config options = {}
      unless @config
        options = validate_options options 
        @config = set_configuration_defaults options
      end
      @config
    end

    def verbose?
      @config[:verbose]
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
