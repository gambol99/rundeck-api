#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
require 'project'

module Rundeck
  class Projects < Base
    def projects 
      get( '/api/1/projects' )['projects'].first['project'].map do |data|
        Rundeck::Project.new data
      end
    end

    def project? name
      !project( name ).nil?
    end

    def project name
      projects.select { |x| x.name == name }.first
    end

    def list
      projects.map { |p| p.name }
    end
  end
end
