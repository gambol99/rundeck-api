#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'uri'

module Rundeck
  module Utils
    class << self 
      def required args, options
        puts "options: #{options}"
        puts "args: #{args}"
        args.each do |x|
          raise ArgumentError, "you have not specified the #{x} option" unless options.has_key? x 
        end
      end

      def valid_url? url 
        url =~ URI::regexp   
      end
    end
  end
end
