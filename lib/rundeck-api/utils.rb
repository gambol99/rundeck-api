#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'uri'

module Rundeck
  module Utils

    def validate_file filename
      raise "the config file: #{filename} does not exist"  unless File.exist? filename
      raise "the config file: #{filename} is not a file"   unless File.file? filename
      raise "the config file: #{filename} is not readable" unless File.readable? filename
      filename
    end

    def required args, options
      args.each do |x|
        raise ArgumentError, "you have not specified the #{x} option" unless options.has_key? x
      end
    end

    def valid_url? url
      url =~ URI::regexp
    end

    def check_format format
      raise "the format: #{format} is invalid, only #{formats.join(', ')} are supported" unless format? format
      format
    end

    def formats
      %(yaml xml)
    end

    def version?
      settings[:verbose]
    end

    def format? format
      formats.include? format
    end
  end
end
