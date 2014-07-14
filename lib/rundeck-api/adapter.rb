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

    private
    def request method, options = {}
      result = nil
      url    = rundeck options[:uri]
      Timeout::timeout( settings[:timeout] || 10 ) do 
        result = HTTParty.send( "#{method}", url, 
          :verify  => false,
          :headers => { 
            'X-Rundeck-Auth-Token' => settings[:api_token],
            'Accept'               => settings[:accepts]
          },
          :query  => options[:body]
        )
      end
      raise Exception, "unable to retrive the request: #{url}" unless result
      unless result.code == 200
        raise Exception, parse_xml(result.body)["error"].last["message"].first
      end
      ( options[:parse] ) ? parse_xml( result.body ) : result.body
    end

    def parse_xml document
      XmlSimple.xml_in( document )
    end

    def rundeck uri
      '%s/%s' % [ settings[:rundeck], uri.gsub( /^\//,'') ]
    end
  end
end
