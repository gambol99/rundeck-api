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
require 'optionscrapper'
require 'colorize'
require 'yaml'
require 'pp'

@parsers  = {
  :jobs  => nil,
  :main  => nil
}
@parsers = nil
@jobs    = {}

def verbose message 
  now = Time.now.strftime('%H:%M:%S')
  puts "[#{now}] ".green << "#{message}".white if message
end

def options data = {}
  @options ||= data
end

def jobs
  return @jobs if !@jobs.empty?
  # step: we create a parse for EACH job
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

def rundeck filename = '.rundeck.yaml'
  path    = File.join(File.dirname(__FILE__), filename )
  raise "the config file: #{path} does not exist"  unless File.exist? path
  raise "the config file: #{path} is not a file"   unless File.file? path
  raise "the config file: #{path} is not readable" unless File.readable? path
  options YAML.load(File.read(path))
end

def project
  @options[:deck]
end

def parser 
  # step: we create the main options parser
  @parser ||= OptionScrapper::new do |o|
    o.banner = "Usage: #{__FILE__} command [options]"
    o.on( '-l', '--list', 'list all the jobs within the project ') do 
      puts <<-EOF

    Project: #{project.name} : a list of jobs under this project 
    =====================================================
    Usage: #{__FILE__} run -n|--name [name] -- [options][--help|-h]

EOF
      project.jobs { |job|
        puts "%32s :    %s" % [ job.name, job.description ]
      }
      puts 
      exit 0
    end
    o.command :import, 'import a jobs or jobs into the current project' do 
      o.on( '-j JOBS', '--jobs JOBS',      'the location of the file contains the job/jobs' )             { |x| options[:jobs]     = x }
      o.on( '-f FORMAT','--format FORMAT', 'the format the jobs file is in (yaml/xml)' )                  { |x| options[:format]   = x }
      o.on( '-u OPTION', '--uuid OPTIONS', 'preserve or remove options for uuids' )                       { |x| options[:uuid]     = x }
      o.on( '-r', '--remove', 'remove the uuid from jobs, allows updateto succeed  (default is true)' )   { |x| options[:remove]   = x }
      o.on( '-D OPTION', '--dupe OPTION', 'the behavior when importing jobs which exist (skip/create/update)' ) { |x| options[:dupe] = x }
      o.on_command { options[:command] = :import }
    end
    o.command :job, 'export a job definition from rundeck' do 
      o.on( '-f FORMAT','--format FORMAT', 'the format the jobs file is in (yaml/xml)' )                  { |x| options[:format]   = x }
      o.on( '-n NAME', '--name NAME', 'the name of the job you wish to export' )                          { |x| options[:job]      = x }
      o.on_command { options[:command] = :job }
    end
    o.command :export, 'export the jobs from the project in the specified format' do 
      o.on( '-f FORMAT', '--format FORMAT',   'the format of the jobs, either yaml or xml (defaults to yaml)') do 
        options[:format] = x 
      end
      o.on_command { options[:command] = :export }
    end
    o.command :run, 'run / execute a job within the project' do 
      o.on( '-n NAME', '--name NAME', 'perform an execution of the job' ) do |job|
        raise ArgumentError, "the job: #{job} does not exist, please check spelling" unless project.list_jobs.include? job
        options[:job] = job
        jobs_options  = ( ARGV.index('--') ) ? ARGV[ARGV.index('--')+1..-1] : ARGV[ARGV.index(job)+1..-1]
        jobs[job].parse! jobs_options
      end
      o.on( '-t', '--tail', 'tail the output of the execution and print to screen' ) { |x| options[:tail] = true  }
      o.on_command { options[:command] = :run }
    end
  end
  @parser
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
  # step: set the defaults
  options[:format] ||= 'yaml'
  options[:remove] ||= false
  options[:dupe]   ||= 'update'
  parser.usage "the format must be either yaml or xml" unless options[:format] =~ /^(yaml|xml)$/
  parser.usage "the dupe policy must be either skip/create/update" unless options[:dupe] =~ /^(skip|create|update)$/
  parser.usage "the uuid options must be eithe preserve or remove" unless options[:uuid] =~ /^(preserve|remove)$/
  parser.usage "the job file: #{options[:jobs]} does not exist"    unless File.exist? options[:jobs]
  parser.usage "the job file: #{options[:jobs]} is not a file"     unless File.file? options[:jobs]
  project.import options[:jobs], options
end

def job
  options[:format] ||= 'yaml'
  parser.usage "you have not specified a job to export the definition"  unless options[:job]
  parser.usage "the job: #{options[:job]} does not exists" unless project.list_jobs.include? options[:job]
  parser.usage "the format must be either yaml or xml" unless options[:format] =~ /^(yaml|xml)$/
  job = project.job options[:job]
  puts job.definition
end

def run 
  job     = project.job options[:job]
  # step: extract the options
  verbose "step: validating the job options for job: #{job.name}"
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
  verbose "step: executing job: #{options[:job]}, project: #{options[:projects]}"
  execution = job.run options[:args]
  verbose "step: execution started, id: #{execution.id}, href: #{execution.href}"
  verbose "step: tailing the execution output"
  execution.tail do |output|
    puts "%s" % [ output.chomp.light_blue ]
  end
  verbose "step: the job has finished, exit status: " << execution.status
  verbose "step: retrieve the execution output:"
  time_took = ( Time.now - start_time )
  verbose "step: time_took: %fms" % [ time_took ] 
  verbose "step: complete"
end

def export project = options[:deck]
  verbose "exporting all the jobs from project: #{options[:project]}"
  puts project.export options[:format] || 'yaml'
end

begin
  deck = Rundeck::API.new rundeck
  options[:deck] = deck.project options['project']
  options[:args] = {}
  # step: parse the command line options
  parser.parse!
  # step: we need to validate the job options are correct
  run    if options[:command] == :run 
  export if options[:command] == :export 
  import if options[:command] == :import  
  job    if options[:command] == :job
rescue Interrupt => e 
  verbose "exiting tho the job: #{options[:job]} might still be running"
rescue ArgumentError => e 
  parser.usage e.message
rescue SystemExit => e 
  exit e.status
rescue Exception => e
  parser.usage e.message
end
