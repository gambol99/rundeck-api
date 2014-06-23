#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
module Rundeck
  module Models
    class Output
      class << self

        def format response
          formated_output = ""
          if response['output'].first.has_key? 'entries'
            response['output'].first['entries'].first['entry'].each do |line|
              formated_output << "%s (user:%s) (node:%s) - %s\n" % 
                [ line['absolute_time'], line['user'], line['node'], line['content'] ]
            end
          end
          formated_output
        end

      end
    end
  end
end
