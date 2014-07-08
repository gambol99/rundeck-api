#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'httparty'
require 'xmlsimple'
require 'utils'

module Rundeck
  module API
    class Session
      include HTTParty
      include Rundeck::Utils

      #debug_output $stderr

      def initialize options
        @options = validate_options options
      end

      def get  uri, body = {}, parse = true
        request :get, uri, { :body => body, :parse => parse } 
      end
      def post uri, body = {}, parse = true
        request :post, uri, { :body => body, :parse => parse }
      end

      private
      def request method, uri, options = {}
        result = nil
        url    = rundeck( uri )
        Timeout::timeout( options[:timeout] || 10 ) do 
          result = self.class.send( "#{method}", url, 
            :headers => { 
              'X-Rundeck-Auth-Token' => @options['api_token'],
              'Accept'               => 'application/xml'
            },
            :query  => options[:body]
          )
        end
        raise Exception, "unable to retrive the request: #{url}"                        unless result
        raise Exception, "invalid response to request: #{url}, error: #{result.body}"   unless result.code == 200
        ( options[:parse] ) ? ::XmlSimple.xml_in( result.body ) : result.body
      end

      def validate_options options 
        required %w(rundeck api_token), options
        # step: check it's a valid url
        raise "the rundeck: #{options['rundeck']} is an invalid url" unless valid_url? options['rundeck']
        # step: set the base uri
        self.class.base_uri options['rundeck']
        options
      end

      def rundeck uri
        '%s/%s' % [ @options['rundeck'], uri.gsub( /^\//,'') ]
      end
    end
  end
end
