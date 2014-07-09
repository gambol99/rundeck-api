#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-07-09 16:12:16 +0100 (Wed, 09 Jul 2014)
#
#  vim:ts=4:sw=4:et
#
require 'session'

module Rundeck
  module Models
    class Base
      include Rundeck::Session 
      include Rundeck::Config

      def check_format format
        raise "the format: #{format} is invalid, only #{formats.join(', ')} are supported" unless format? format
        format
      end

      def formats 
        %(yaml xml)
      end

      def format? format
        formats.include? format
      end
    end
  end
end
