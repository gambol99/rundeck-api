#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
module Rundeck
  class Output
    class << self
      def format response
        formated_output = ""
        if output( response ).has_key? 'entries' and !output( response )['entries'].first.empty?
          output( response )['entries'].first['entry'].each do |line|
            formated_output << "%s (%s) : %s\n" % [ line['absolute_time'], line['node'], (line['content']||'').chomp ]
          end
        end
        formated_output
      end

      def offset response 
        output( response )['offset'].first
      end

      def output response
        response['output'].first if response['output'].first 
      end
    end
  end
end
