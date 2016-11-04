#!/usr/bin/env ruby
#
# Purpose:
# 	Command line tool to generate key and iv values for
# 	provided cipher method and print them as base64 encoded
# 	strings
#
# Requires:
# 	- ruby with openssl support

require 'openssl'
require 'base64'
require 'optparse'

# check if supplied cipher exists and supported by openssl
def cipher_supported?(cipher)
  stat = false
  OpenSSL::Cipher.ciphers.each do |c|
    stat = true if (c==cipher)
  end
  stat
end

options = {}
cipher_called = false

opt_parser =OptionParser.new do |opts|
  opts.banner = 'Usage: gen_key_iv.rb [options]'

  options[:cipher] = nil
  opts.on('-c', '--cipher [CIPHER]', String, 'Cipher to use') do |c|
    if cipher_supported?(c)
      options[:cipher] = c
      cipher_called = true
    else
      cipher_called = true
      if c.nil?
        puts '[Error] Cipher string cannot be empty'
      else
        puts '[Error] Cipher is not supported by OpenSSL'
      end
      puts opt_parser
    end
  end

  options[:show_ciphers] = false
  opts.on('-s', '--show-ciphers', 'List all supported ciphers') do |s|
    options[:show_ciphers] = s
  end

  opts.on('-h', '--help', 'Show help') do |h|
    options[:help] = h
    puts opt_parser
    exit
  end
end

begin
  opt_parser.parse!

  if (!cipher_called && !options[:show_ciphers] && options[:cipher].nil?)
    puts '[Error] At least one option is required'
    puts opt_parser
    exit 1
  end

  if (options[:show_ciphers] && options[:cipher])
    puts '[Error] Unable to use both options'
    puts opt_parser
    exit 1
  end

  if (options[:show_ciphers])
    puts 'List of supported ciphers:'
    puts OpenSSL::Cipher.ciphers
    exit
  end

  if (options[:cipher] && cipher_called)
    begin
      cipher = OpenSSL::Cipher.new(options[:cipher])
      cipher.encrypt
      key =Base64.encode64(cipher.random_key).tr("\n", "")
      iv =Base64.encode64(cipher.random_iv).tr("\n", "")
      puts sprintf 'Provided: %s', options[:cipher]
      puts sprintf 'Status: %s', 'Done'
      puts 'Copy lines below to your configuration file:'
      puts
      puts 'encryption:'
      puts sprintf "\tcipher: '%s'", options[:cipher]
      puts sprintf "\tkey: '%s'", key
      puts sprintf "\tiv: '%s'", iv

      exit
    rescue
      puts "[Error] Unable to generate key and iv for #{options[:cipher]}"
      exit 1
    end
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts opt_parser
  exit
end
