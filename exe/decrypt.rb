#!/usr/bin/env ruby
# Purpose:
# Command line tool to decrypt JIRA backup file
#
# Requires:
# 	- ruby with openssl support
# 	- backup file
#	  - original config file that was used to encrypt backup

require 'openssl'
require 'base64'
require 'optparse'
require 'yaml'

require_relative '../lib/encryption'

options = {}

opt_parser =OptionParser.new do |opts|
  opts.banner = 'Usage: decrypt.rb [options]'

  options[:file] = nil
  opts.on('-f', '--file FILE', String, 'Encrypted backup file') do |f|
    options[:file] = f
  end

  options[:config] = nil
  opts.on('-c', '--config CONFIG', String, 'config.yml file used for file encryption') do |c|
    options[:config] = c
  end

  opts.on('-h', '--help', 'Show help') do |h|
    options[:help] = h
    puts opt_parser
    exit
  end

  opts.on('-v', '--version', 'Show current version') do |v|
    options[:version] = v
    puts Atlassian::Jira::Backup::VERSION
    exit
  end
end

begin
  opt_parser.parse!

  required = [:file, :config]
  missing = required.select { |param| options[param].nil? }
  unless missing.empty?
    puts "Missing options: #{required.join(', ')}"
    puts opt_parser
    exit
  end

  begin
    config = YAML.load_file(options[:config])
    enc_opts = config['encryption']
    enc = Atlassian::Encryption.new(enc_opts['cipher'], enc_opts['key'], enc_opts['iv'])
    enc.processFile(options[:file], true)
  rescue
    puts $!.to_s
    exit
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts opt_parser
  exit
end

