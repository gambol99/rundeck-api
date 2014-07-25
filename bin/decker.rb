#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'rundeck-api'

module Rundeck
  class Decker < CLI
    def initialize
      begin
        # generate and parse the command line
        parser.parse!
        # load the configuration
        settings options[:config]
        # pull the jobs from the project
        generate_job_parsers
        # step call the command
        send options[:command] if options[:command]
      rescue SystemExit => e
        exit e.status
      rescue Exception => e
        parser.usage e.message
      end
    end

    private
    def list
      options[:name] ||= '.*'
      options[:group] ||= '.*'
      newline
      puts "  %-32s %s".green % [ "JOB NAME", "DESCRIPTION" ]
      puts "   > rundeck: %s, project: %s".green % [ rundeck['rundeck'], project_name ]
      newline
      project.jobs do |job|
        next unless job.name =~ /.*#{options[:name]}.*/
        next unless job.group =~ /.*#{options[:group]}.*/
        puts "  %-32s %s (%s)" % [ job.name, job.description || 'no description', job.group.blue ]
      end
      newline
    end

    def generate_job_parsers arguments = :args
      @job_parsers ||= {}
      if @job_parsers.empty?
        project.jobs do |job|
          @job_parsers[job.name] = OptionParser::new do |o|
            o.banner = ''
            o.separator "\tjob: #{job.name}     : #{job.description}"
            o.separator ''
            job.options.each do |option|
              option_name = option['name']
              description = ( option['description'] || [] ).first || "no description for this option"
              if option['values'] or option['value']
                description << " ( "
                description << "defaults: '#{option['value'].blue}' " if option['value']
                description << "options: '#{option['values'].blue}' " if option['values']
                description << ")"
              end
              o.on( "--#{option_name} #{option_name.upcase}", description ) { |x| options[arguments][option_name.to_sym] = x   }
            end
            o.separator ''
          end
        end
      end
      @job_parsers
    end

    def job_parser name
      generate_job_parsers[name]
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
      announce "attemping to import the job definitions from file: #{options[:filename]}"
      project.import File.read(options[:filename]), options
      announce "successfully imported the definitions"
    end

    def exec
      # fail if we do not have a job to execute
      fail "you have not specified a job to run" unless options[:job]
      # pull the job defined from rundeck
      job = project.job options[:job]
      # we need to parse the options of the job
      parse_job_options

      # extract the options and validate against what the user has provided
      announce "validating the job options for job: #{job.name}"
      job.options.each do |option|
        name = option['name'].to_sym
        # check: if the option does not have a default - we need to make sure a value has been given
        if option['required'] == 'true' and !option['value']
          raise ArgumentError, "you have not specified the #{name} option" unless options[:args][name]
        end
      end
      start_time = Time.now
      # call the job the specified arguments
      announce "executing job: #{options[:job]}, project: #{project_name}"
      #announce "average execution time based on history: %f" % [ job.average_time ] if job.a
      execution = job.run options[:args]
      announce "execution started, id: #{execution.id}, href: #{execution.href}"
      announce "tailing the execution output"
      execution.tail do |output|
        announce( "%s" % [ output.chomp ], { :color => :light_blue } )
      end
      announce "the job has finished, exit status: " << execution.status
      time_took = ( Time.now - start_time )
      announce "job execution time: %fms" % [ time_took ]
      announce "execution complete"
    end

    def export
      fail "we do not support the xml format at the moment" if options[:format] == 'xml'
      options[:format] ||= 'yaml'
      # are we exporting a single job?
      if options[:job]
        fail "you have not specified a job to export the definition"  unless options[:job]
        fail "the job: #{options[:job]} does not exists" unless project.list.include? options[:job]
        job = project.job options[:job]
        puts job.definition options[:format]
      else
        definitions = project.export options[:format]
        if options[:single]
          directory = validate_directory options[:directory]
          directory ||= './'
          YAML.load(definitions).each do |job|
            file_name = "%s%s" % [ directory, job['name'].gsub(/[ ]+/,'_') << "." << options[:format] ]
            File.open( file_name, 'w' ) { |x| x.puts job.to_yaml }
          end
        else
          puts definitions
        end
      end
    end

    def parse_job_options
      job_parser( options[:job] ).parse! options[:job_options]
    end

    def parser
      # we create the main options parser
      @parser ||= OptionScrapper::new do |o|
        o.banner = "Usage: #{__FILE__} command [options]"
        o.on( '-c CONFIG', '--config CONFIG', "the path / location of the configuration file (#{default_configuration})") { |x| options[:config] = x }
        o.on( '-r RUNDECK', '--rundeck RUNDECK', 'the configuration can contain multiple rundecks' ) { |x| options[:rundeck] = x }
        o.command :list, 'list all the jobs with the selected project' do
          o.command_alias :ls
          o.on( '-n NAME', '--name NAME', 'the name of the job you wish to export, regex' ) { |x| options[:name] = x }
          o.on( '-g GROUP', '--group GROUP', 'list job only within this group, regex' ) { |x| options[:group] = x }
          o.on_command { options[:command] = :list }
        end
        o.command :exec, 'run / execute a job within the project' do
          o.command_alias :r
          o.on( '-n NAME', '--name NAME', 'perform an execution of the job' ) do |job|
            options[:job] = job
            options[:job_options] = ( ARGV.index('--') ) ? ARGV[ARGV.index('--')+1..-1] : ARGV[ARGV.index(job)+1..-1]
          end
          o.on( '-t', '--tail', 'tail the output of the execution and print to screen' ) { |x| options[:tail] = true  }
          o.on( '-h', '--help', 'display the options for this job' ) do
            settings options[:config]
            if options[:job]
              puts job_parser options[:job]
              exit 0
            end
          end
          o.on_command {  options[:command] = :exec }
        end
        o.command :activity, 'interrogate the rundeck activity and history' do
          o.command_alias :his
          o.on( '-n JOB_NAME', '--name JOB_NAME', 'filter the activity by the job name, regex' ) { |x| options[:name] = x }
          o.on( '-i ID', '--id ID', 'the id of the activity you are interested in' ) { options[:id] = x }
          o.on( '-g GROUP', '--group GROUP', 'filter the activity by the group name, regex' ) { |x| options[:group] = x }
          o.on( '-R', '--running', 'only show activity which is current running' ) { options[:running] = true }
          o.on( '-S', '--stopped', 'only show activity which has stopped' ) { options[:stopped] = true }
          o.on( '-F', '--failed', 'only show activity which has failed' ) { options[:failed] = true }
          o.on( '-o', '--output', 'view the output of the activity or tail the running job' ) { options[:output] = true }
        end
        o.command :import, 'import a jobs or jobs into the current project' do
          o.command_alias :imp
          o.on( '-j JOBS', '--jobs JOBS',      'the location of the file contains the job/jobs' ) { |x| options[:filename] = x }
          o.on( '-f FORMAT','--format FORMAT', 'the format the jobs file is in (yaml/xml)' ) { |x| options[:format] = x }
          o.on( '-u OPTION', '--uuid OPTIONS', 'preserve or remove options for uuids' ) { |x| options[:uuid] = x }
          o.on( '-r', '--remove', 'remove the uuid from jobs, allows updateto succeed  (default is true)' ) { |x| options[:remove] = x }
          o.on( '-D OPTION', '--dupe OPTION', 'the behavior when importing jobs which exist (skip/create/update)' ) { |x| options[:dupe] = x }
          o.on_command { options[:command] = :import }
        end
        o.command :export, 'export the jobs from the project in the specified format' do
          o.command_alias :exp
          o.on( '-f FORMAT', '--format FORMAT', 'the format of the jobs, either yaml or xml (defaults to yaml)') { |x| options[:format] = x }
          o.on( '-n NAME', '--name NAME', 'the name of the job you wish to export' ) { |x| options[:job] = x }
          o.on( '-d DIRECTORY', '--directory DIRECTORY', 'the directory to place the single jobs' ) { |x| options[:directory] = x }
          o.on( '-s', '--single', 'export the jobs in single files' ) { options[:single] = true }
          o.on_command { options[:command] = :export }
        end
      end
      @parser
    end
  end
end

Rundeck::Decker.new
