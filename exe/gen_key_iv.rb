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

options = {}

opt_parser =OptionParser.new do |opts|
  opts.banner = 'Usage: gen_key_iv cipher [options]'
  opts.on('-s', '--show-ciphers', 'List all supported ciphers') do |s|
    options[:show_ciphers] = s
  end

  opts.on('-g', '--generate', 'Generate key and iv with selected cipher') do |g|
    options[:gen_key_iv] = g
  end

  opts.on('-h', '--help', 'Show help') do |h|
    options[:help] = h
    puts opt_parser
  end
end
opt_parser.parse!

case ARGV[0]
when 'cipher'
  ARGV.shift
  # Listing all ciphers supported by openssl
  if options[:show_ciphers]
    puts 'List of supported ciphers:\n'
    puts OpenSSL::Cipher.ciphers
    exit 0
  end

  # Using cipher to generate key and iv
  if options[:gen_key_iv] && !ARGV.empty?
    cipher_method = ARGV[0]
    begin
      cipher = OpenSSL::Cipher.new(cipher_method)
      cipher.encrypt
      key =Base64.encode64(cipher.random_key)
      iv =Base64.encode64(cipher.random_iv)
      puts "Provided: #{cipher_method}\n"
      puts "Generated:\n\tkey:#{key}\tiv:#{iv}"
      exit 0
    rescue
      puts "[Error] Unable to generate key and iv for #{cipher_method}"
      exit 1
    end
  else
    puts '[Error] Please provide cipher method\n'
    exit 1
  end

  if options.empty?
    puts '[Error] Please provide necessary options first\n'
    puts opt_parser
    exit 1
  end
else
  puts opt_parser
  exit 0
end
