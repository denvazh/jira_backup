require 'yaml'
require 'date'
require './lib/version.rb'

module Atlassian
  extend Atlassian

  class Jira
    attr :protocol
    attr :dashboard
    attr :runbackup
    attr :backupdir

    def initialize
      @protocol ='https'
      @dashboard ='Dashboard.jspa'
      @runbackup ='rest/obm/1.0/runbackup'
      @backupdir ='webdav/backupmanager'
    end

    class Backup

      DEFAULT_CONFIG='config.yml'

      attr :instance
      attr :username
      attr :password
      attr :encryption
      attr :date
      attr :fileformat

      attr :curlsession
      attr :connected
      attr :created
      attr :errmsg

      def initialize(configFile=nil)

        config = readconf(configFile)

        if verifyconf(config)
          @instance =config['instance']
          @username =config['username']
          @password =config['password']

          enc =config['encryption']
          @encryption =Encryption.new(enc['cipher'], enc['key'], enc['iv'])

          @curlsession =Curl::Easy.new
          @connected =false
          @created =false
          @errmsg =nil
          @date =Time.now
          @fileformat ="JIRA-backup-#{date.strftime('%Y%m%d')}.zip"
        end
      end

      def readconf(configFile=nil)
        file = configFile ? configFile : DEFAULT_CONFIG
        begin
          conf = YAML::load_file(file)
          return conf
        rescue Errno::ENOENT
          puts '[Error] ' + $!.to_s
          exit
        end
      end

      def verifyconf(yml)
        expected = ['instance', 'username', 'password', 'encryption']

        # check if all keys was set properly
        valid_keys = expected.all? { |e| yml.keys.include?(e) }

        # check if all values for keys is at least not null
        valid_values = yml.all? { |k, v| v.nil? || v.empty? || v.size == 0 }

        return valid_keys || valid_values ? true : false
      end

      def connect(protocol, request_uri)
        @connected =false

        url ="#{protocol}://#{@instance}/#{request_uri}"
        headers ={}
        headers['X-Atlassian-Token']='no-check'

        @curlsession.url = url
        @curlsession.http_auth_types = :basic
        @curlsession.username = @username
        @curlsession.password = @password
        @curlsession.enable_cookies = true
        @curlsession.headers=headers
        @curlsession.perform

        # set flag to connected
        if (@curlsession.response_code == 200 && @curlsession.enable_cookies?)
          @connected = true
        end

        return @connected
      end

      def connected?
        return @connected ? true : false;
      end

      def create(protocol, request_uri)
        url = "#{protocol}://#{@instance}/#{request_uri}"
        headers ={}
        headers['X-Atlassian-Token']='no-check'
        headers['X-Requested-With']='XMLHttpRequest'
        headers['Content-Type']='application/json'
        headers['Accept']='application/json'
        data = "{\"cbAttachments\":\"true\"}"

        if (connected?)
          @curlsession.url = url
          @curlsession.headers=headers
          @curlsession.http_post(data)

          if (checkStatus(@curlsession.response_code, @curlsession.body_str))
            return true
          else
            puts "[Warning] #{@errmsg}"
            return false
          end
        else
          return false
        end
      end

      def checkStatus(response_code, response_str)
        @created = false

        if (response_code == 200)
          @created = true
        end

        # Backup already exists
        if (response_code == 500 && response_str.length > 1)
          @errmsg = response_str
        end

        return @created
      end

      def created?
        return @created ? true : false;
      end

      #
      # Checking if file is available (using HEAD request)
      #
      def fileIsAvailable(protocol, request_uri, fileformat)
        url = "#{protocol}://#{@instance}/#{request_uri}/#{fileformat}"
        headers ={}
        headers['X-Atlassian-Token']='no-check'

        if (connected?)
          #@curlsession.verbose = true
          @curlsession.url = url
          @curlsession.headers=headers
          @curlsession.follow_location = true
          @curlsession.http_head

          if ((@curlsession.response_code == 200) &&
            @curlsession.content_type == 'application/zip')
            return true
          else
            return false
            #raise 'An error has occured. Unable to find requested file.'
          end
        end
      end

      #
      # Actually downloading file
      #
      # @returns filename
      #
      def fetchFile(protocol, request_uri, fileformat)
        url = "#{protocol}://#{@instance}/#{request_uri}/#{fileformat}"
        headers ={}
        headers['X-Atlassian-Token']='no-check'

        if (connected?)
          @curlsession.url = url
          @curlsession.headers=headers
          @curlsession.follow_location = true

          @curlsession.on_body { |data|
            File.open(fileformat, 'a') { |f|
              f.write data
            }
          }

          @curlsession.perform
        end

        return File.exists?(fileformat) ? fileformat : nil
      end

    end # class Backup
  end # class Jira
end # module Jira
