require 'yaml'
require 'openssl'
require 'base64'
require 'json'

require 'bundler/setup'
require 'curb'

module Atlassian
  class Jira
    attr :protocol
    attr :dashboard
    attr :runbackup

    def initialize
      @protocol ='https'
      @dashboard ='Dashboard.jspa'
      @runbackup ='rest/obm/1.0/runbackup'
    end

    class Backup
      attr :instance
      attr :username
      attr :password
      attr :encryption

      attr :curlsession
      attr :connected

      def initialize
        config = YAML::load_file('config.yml')
        if verifyconf(config)
          @instance =config['instance']
          @username =config['username']
          @password =config['password']

          enc = config['encryption']
          @encryption = Encryption.new(enc['cipher'], enc['key'], enc['iv'])

          @curlsession = Curl::Easy.new
        end
      end

      def verifyconf(yml)
        expected = %w(instance username password encryption)

        # check if all keys was set properly
        valid_keys = expected.all? { |e| yml.keys.include?(e) }

        # check if all values for keys is at least not null
        valid_values = yml.all? { |_k, v| v.nil? || v.empty? || v.size == 0 }

        (valid_keys || valid_values)
      end

      def connect(protocol, request_uri)
        @connected =false

        url ="#{protocol}://#{@instance}/#{request_uri}"
        headers ={}
        headers['X-Atlassian-Token']='no-check'

        #@curlsession.verbose = true
        @curlsession.url = url
        @curlsession.http_auth_types = :basic
        @curlsession.username = @username
        @curlsession.password = @password
        @curlsession.enable_cookies = true
        @curlsession.headers=headers
        @curlsession.perform

        # set flag to opened
        if @curlsession.response_code == 200 && @curlsession.enable_cookies?
          @connected = true
        end

        @connected
      end

      def connected?
        @connected
      end

      def create(protocol, request_uri)
        url = "#{protocol}://#{@instance}/#{request_uri}"
        headers ={}
        headers['X-Atlassian-Token']='no-check'
        headers['X-Requested-With']='XMLHttpRequest'
        headers['Content-Type']='application/json'
        headers['Accept']='application/json'

        data = { 'cbAttachments' => 'true' }

        return false unless connected?

        @curlsession.url = url
        @curlsession.verbose = true
        @curlsession.headers=headers
        @curlsession.http_post(url, data)
        puts @curlsession.header_str
        puts @curlsession.body_str
      end
    end # class Backup
  end # class Jira

  class Encryption
    attr :cipher
    attr :key
    attr :iv

    def initialize(cipher, key, iv)
      @cipher =cipher
      @key =key
      @iv =iv
    end

    def processFile(file, decrypt=false)
      cipher = OpenSSL::Cipher.new(@cipher)
      suffix = ''
      if decrypt
        suffix += 'decrypted'
        cipher.decrypt
      else
        suffix += 'encrypted'
        cipher.encrypt
      end

      # key and iv stored in base64 format
      key = Base64.decode64(@key)
      iv = Base64.decode64(@iv)

      basename = file.sub(File.extname(file), '')
      dst_file = "#{basename}.#{suffix}"

      if File.exist?(file)
        buf = ''
        File.open(dst_file, 'wb') do |outf|
          File.open(file, 'rb') do |inf|
            while inf.read(4096, buf)
              outf << cipher.update(buf)
            end
            outf << cipher.final
          end
        end
      else
        puts "[Warning] #{file} do not exist"
      end
    end
  end # class Encryption
end # module Jira

## [ MAIN ][ START ] ##

jira =Atlassian::Jira.new
backup =Atlassian::Jira::Backup.new
backup.connect(jira.protocol, jira.dashboard)
backup.create(jira.protocol, jira.runbackup)

## [ MAIN ][ END ] ##

