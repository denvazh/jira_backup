require 'openssl'
require 'base64'

def decode64(str)
  Base64.decode64(str)
end

# encryption
cipher = OpenSSL::Cipher.new('aes-256-cbc')
cipher.encrypt
key = decode64('somekey')
iv = decode64('someiv')

cipher.key =key
cipher.iv =iv

buf = ''
File.open('JIRA-backup.encrypted', "wb") do |outf|
  File.open('JIRA-backup.zip', "rb") do |inf|
    while inf.read(4096, buf)
      outf << cipher.update(buf)
    end
    outf << cipher.final
  end
end

exit 1

# decryption
cipher = OpenSSL::Cipher.new('aes-256-cbc')
cipher.decrypt
cipher.key = key
cipher.iv = iv # key and iv are the ones from above

buf = ''
File.open('file.dec', 'wb') do |outf|
  File.open('file.enc', 'rb') do |inf|
    while inf.read(4096, buf)
      outf << cipher.update(buf)
    end
    outf << cipher.final
  end
end
