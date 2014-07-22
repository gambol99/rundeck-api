#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'httparty'
require 'xmlsimple'

module Rundeck
  module Adapter
    include HTTParty
    [ :get, :post, :delete ].each do |m|
      define_method "#{m}" do |uri,content = {},parse = true|
        request( m, {
          :uri   => uri,
          :body  => content,
          :parse => parse
        } )
      end
    end

    def request method, options = {}
      result = nil
      url = rundeck options[:uri]
      begin 
        Timeout::timeout( settings[:timeout] || 10 ) do
          http_options = {
            :verify  => verify_ssl,
            :headers => default_headers
          }
          case method
            when :post
              http_options[:body]  = options[:body]
            else
              http_options[:query] = options[:body]
          end
          result = HTTParty.send( "#{method}", url, http_options )
        end
        raise Exception, "unable to retrive the request: #{url}" unless result
        unless result.code == 200
          raise Exception, parse_xml(result.body)["error"].last["message"].first rescue result.body
        end
        ( options[:parse] ) ? parse_xml( result.body ) : result.body
      rescue Timeout::Error 

      rescue Exception => e 

      end
    end

    def default_headers 
      {
        'X-Rundeck-Auth-Token' => settings[:api_token],
        'Accept' => settings[:accepts]
      }
    end

    def verify_ssl
      options[:verify_ssl] || false
    end

    def parse_xml document
      XmlSimple.xml_in( document )
    end

    def rundeck uri
      '%s/%s' % [ settings[:rundeck], uri.gsub( /^\//,'') ]
    end
  end
end
