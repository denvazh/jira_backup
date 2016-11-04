JIRA On-Demand Backup
---------------------

Creates backups of Jira for configured domain.

## Security note

> Important!
> 
> Because this solution involved in creating and storing account information in plain text (along with key and iv for encryption/decryption) it is important to limit access to the backup server and make sure nobody expect root/backup user has access priveledges to the information stored in **config.yml** file.

## How to configure

By default, script jirabackup.rb expects configuration file **config.yml**
in the same directory.

Using option **-c** or **--conf** it is possible to supply this file from any other directory in the file system.

	example: ruby jirabackup.rb --conf $HOME/config.yml

### Structure of config.yml

Configuration file is expected to have the following structure:

	instance: '%hostname%'
	username: '%username%'
	password: '%password%'
	encryption:
    	cipher: 'des-cbc'
    	key: 'dGhpcyBpcyB0ZXN0Cg=='
    	iv: 'YVhZZ2FYTWdkR2hsSUhSbGMzUWdabTl5SUdsMENnPT0K'

where one has to provide the following

* instance - hostname of your on-demand instance
* username - username of user with admin permissions
* password - plain text password for username

encryption portion of configuration file can be generated with **gen_key_iv.rb**.

## How to decrypt

In a normal scenario, all backups are encrypted with original zip archive file being deleted (md5 hash are generated for both, though).

For recovery purposes it would be necessary to decrypt backup file back to its original state.

This has to be done with **decrypt.rb** script:

	decrypt.rb --config config.yml --file backup.zip

It is important to use **config.yml** backup.zip file was encrypted with, otherwise it won't be possible to decrypt it.
