require 'openssl'
require 'base64'
require './lib/version.rb'

module Atlassian
	extend Atlassian

	class Encryption
		attr :cipher
		attr :key
		attr :iv

		def initialize(cipher, key, iv)
			@cipher	=cipher

			# key and iv assumed to be in base64
			@key	=decode64(key)
			@iv		=decode64(iv)
		end

		def decode64(str)
			return Base64.decode64(str)
		end

		def processFile(file, decrypt=false)
			cipher = OpenSSL::Cipher.new(@cipher)

			suffix	=""
			if (decrypt)
				suffix += "decrypted"
				cipher.decrypt
			else
				suffix += "encrypted"
				cipher.encrypt
			end
			cipher.key = @key
			cipher.iv = @iv

			basename = file.sub(File.extname(file),"")
			dst_file = "#{basename}.#{suffix}"

			if File.exist?(file)
				buf = ""
				File.open(dst_file, "wb") do |outf|
					File.open(file, "rb") do |inf|
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
end # module Atlassian
