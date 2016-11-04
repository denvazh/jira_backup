#!/usr/bin/env ruby

require 'optparse'
require 'bundler/setup'
require 'curb'

require_relative '../lib/backup'
require_relative '../lib/encryption'

## [ MAIN ][ START ] ##

# parsing ARGV options
options = {}
jira =Atlassian::Jira.new

opt_parser =OptionParser.new do |opts|
  opts.banner = 'Usage: jirabackup.rb [options]'

  options[:config] = nil
  opts.on('-c', '--conf [CIPHER]', String,
          'Configuration file to use [Default: config.yml]') do |c|
    options[:config] = c
  end

  opts.on('-h', '--help', 'Show help') do |h|
    options[:help] = h
    puts opt_parser
    exit
  end

  opts.on('-v', '--version', 'Show current version') do |v|
    options[:version] = v
  end
end

begin
  opt_parser.parse!

  if (options[:version])
    puts Atlassian::Jira::Backup::VERSION
    exit
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts opt_parser
  exit
end

BACKUPATTEMPTS=20
CHECKATTEMPTS=20

backup =Atlassian::Jira::Backup.new(options[:config])

backup.connect(jira.protocol, jira.dashboard)

backup_created = false
BACKUPATTEMPTS.times do
  backup_created = backup.create(jira.protocol, jira.runbackup)
  sleep 5 unless backup_created
end

# if file is huge enough it will take a while to create it
fileIsAvailable = false

# make 20 attempts to check if backup file is available
# wait 5 seconds after each attempt
# total time: 20*5=100 sec
CHECKATTEMPTS.times do |t|
  available = backup.fileIsAvailable(jira.protocol, jira.backupdir, backup.fileformat)
  if (available)
    fileIsAvailable = true
  else
    sleep 5
  end
end

if fileIsAvailable
  # downloading file
  currentBackup = backup.fetchFile(jira.protocol, jira.backupdir, backup.fileformat)

  # encrypting backup file
  backup.encryption.processFile(currentBackup)
else
  puts '[Error] Backup file is not available'
  exit 1
end
## [ MAIN ][ END ] ##
