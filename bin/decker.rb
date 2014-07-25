#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#

$: << '/home/jest/scm/github/optionscrapper/lib'
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'rundeck-api'

module Rundeck
  class Decker < CLI
    def initialize
      begin
        # step: generate and parse the command line
        parser.parse!
        # step: load the configuration
        settings options[:config]
        # step: pull the jobs from the project
        project
        # step call the command
        send options[:command]
      rescue SystemExit => e
        exit e.status
      rescue Exception => e
        parser.usage e.message
      end
    end

    private
    def list
      newline
      puts "  %-32s %s".green % [ "JOB NAME", "DESCRIPTION" ]
      puts "   > rundeck: %s, project: %s".green % [ rundeck['rundeck'], rundeck['project'] ]
      newline
      project.jobs do |job|
        puts "  %-32s %s (%s)" % [ job.name, job.description || 'no description', job.group.blue ]
      end
      newline
    end

    def nothing
      project.jobs do |job|
        @jobs[job.name] = OptionParser::new do |o|
          o.banner = ''
          o.separator "\tjob: #{job.name}     : #{job.description}"
          o.separator ''
          job.options.each do |option|
            option_name      = option['name']
            description      = ( option['description'] || [] ).first || "no description for this option"
            if description

            end
            if option['values'] or option['value']
              description << " ( "
              description << "defaults: '#{option['value'].blue}' " if option['value']
              description << "options: '#{option['values'].blue}' " if option['values']
              description << ")"
            end
            o.on( "--#{option_name} #{option_name.upcase}", description ) { |x| options[:args][option_name.to_sym] = x   }
          end
          o.separator ''
        end
      end
      @jobs
    end

    #
    # format : can be "xml" or "yaml" to specify the output format. Default is "xml"
    # dupeOption: A value to indicate the behavior when importing jobs which already exist. Value can be "skip", "create", or "update". Default is "create".
    # project : (since v8) Specify the project that all job definitions should be imported to. If not specified, each job definition must define the project to import to.
    # uuidOption: Whether to preserve or remove UUIDs from the imported jobs. Allowed values (since V9):
    # preserve: Preserve the UUIDs in imported jobs. This may cause the import to fail if the UUID is already used. (Default value).
    # remove: Remove the UUIDs from imported jobs. Allows update/create to succeed without conflict on UUID.
    #
    def import
      options[:format] ||= 'yaml'
      options[:remove] ||= false
      options[:dupe]   ||= 'update'
      options[:uuid]   ||= 'remove'
      fail "the format must be either yaml or xml" unless options[:format] =~ /^(yaml|xml)$/
      fail "the dupe policy must be either skip/create/update" unless options[:dupe] =~ /^(skip|create|update)$/
      fail "the uuid options must be eithe preserve or remove" unless options[:uuid] =~ /^(preserve|remove)$/
      fail "the job file: #{options[:filename]} does not exist" unless File.exist? options[:filename]
      fail "the job file: #{options[:filename]} is not a file" unless File.file? options[:filename]
      announce "step: attemping to import the job definitions from file: #{options[:filename]}"
      project.import File.read(options[:filename]), options
      announce "step: successfully imported the definitions"
    end

    def exec
      job = project.job options[:job]
      # step: extract the options
      announce "step: validating the job options for job: #{job.name}"
      job.options.each do |option|
        option_name = option['name']
        # check: if the option does not have a default - we need to make sure a value has been given
        if option['required'] == 'true' and !option['value']
          raise ArgumentError, "you have not specified the #{option_name} option" if !options[:args][option_name.to_sym]
        end
        # check: if the option has a regex, lets validate it
        if option['regex'] and !options[:args][option_name.to_sym] =~ /#{option['regex']}/
          raise ArgumentError, "the option: #{option_name} is invalid, does not match regex: #{option['regex']}"
        end
      end
      start_time = Time.now
      # step: call the job the specified arguments
      announce "step: executing job: #{options[:job]}, project: #{options[:projects]}"
      execution = job.run options[:args]
      announce "step: execution started, id: #{execution.id}, href: #{execution.href}"
      announce "step: tailing the execution output"
      execution.tail do |output|
        puts "%s" % [ output.chomp.light_blue ]
      end
      announce "step: the job has finished, exit status: " << execution.status
      announce "step: retrieve the execution output:"
      time_took = ( Time.now - start_time )
      announce "step: time_took: %fms" % [ time_took ]
      announce "step: complete"
    end

    def export
      fail "we do not support the xml format at the moment" if options[:format] == 'xml'
      # step: are we exporting a single job?
      options[:format] ||= 'yaml'
      if options[:job]
        fail "you have not specified a job to export the definition"  unless options[:job]
        fail "the job: #{options[:job]} does not exists" unless project.list.include? options[:job]
        fail "the format must be either yaml or xml" unless options[:format] =~ /^(yaml|xml)$/
        job = project.job options[:job]
        puts job.definition options[:format]
      else
        definitions = project.export options[:format]
        if options[:single]
          YAML.load(definitions).each do |job|
            file_name = job['name'].gsub(/[ ]+/,'_') << "." << options[:format]
            File.open( file_name, 'w' ) do |x|
              x.puts job.to_yaml
            end
          end
        else
          puts definitions
        end
      end
    end

    def parser
      # step: we create the main options parser
      @parser ||= OptionScrapper::new do |o|
        o.banner = "Usage: #{__FILE__} command [options]"
        o.on( '-c CONFIG', '--config CONFIG', 'the path / location of the configuration file ') { |x| options[:config] = x }
        o.on( '-r RUNDECK', '--rundeck RUNDECK', 'the configuration can contain multiple rundecks' ) { |x| options[:rundeck] = x }
        o.command :projects, 'list all the projects within rundeck' do
          o.on_command { options[:command] = :projects }
        end
        o.command :list, 'list all the jobs with the selected project' do
          o.on_command { options[:command] = :list }
        end
        o.command :exec, 'run / execute a job within the project' do
          o.on( '-n NAME', '--name NAME', 'perform an execution of the job' ) do |job|
            options[:job] = job
            options[:job_options] = ( ARGV.index('--') ) ? ARGV[ARGV.index('--')+1..-1] : ARGV[ARGV.index(job)+1..-1]
          end
          o.on( '-t', '--tail', 'tail the output of the execution and print to screen' ) { |x| options[:tail] = true  }
          o.on( '-h', '--help', 'display the options for this job' ) { options[:usage] = true }
          o.on_command {  options[:command] = :run }
        end
        o.command :import, 'import a jobs or jobs into the current project' do
          o.on( '-j JOBS', '--jobs JOBS',      'the location of the file contains the job/jobs' ) { |x| options[:filename] = x }
          o.on( '-f FORMAT','--format FORMAT', 'the format the jobs file is in (yaml/xml)' ) { |x| options[:format] = x }
          o.on( '-u OPTION', '--uuid OPTIONS', 'preserve or remove options for uuids' ) { |x| options[:uuid] = x }
          o.on( '-r', '--remove', 'remove the uuid from jobs, allows updateto succeed  (default is true)' ) { |x| options[:remove] = x }
          o.on( '-D OPTION', '--dupe OPTION', 'the behavior when importing jobs which exist (skip/create/update)' ) { |x| options[:dupe] = x }
          o.on_command { options[:command] = :import }
        end
        o.command :export, 'export the jobs from the project in the specified format' do
          o.on( '-f FORMAT', '--format FORMAT', 'the format of the jobs, either yaml or xml (defaults to yaml)') { |x| options[:format] = x }
          o.on( '-n NAME', '--name NAME', 'the name of the job you wish to export' ) { |x| options[:job] = x }
          o.on( '-s', '--single', 'export the jobs in single files' ) { options[:single] = true }
          o.on_command { options[:command] = :export }
        end
      end
      @parser
    end
  end
end

Rundeck::Decker.new
