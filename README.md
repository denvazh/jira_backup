# Jira::Backup

Creates backup snapshot for configured JIRA domain.

Could be used to run inside travis jobs, in this case recommended setup would be as follows:

- request to run cron jobs for given repository: https://docs.travis-ci.com/user/cron-jobs/
- configure scripts in this project to download daily backup of JIRA domain
- use travis publish feature to upload snapshot file to corresponding datastore (such as Amazon S3)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jira-backup'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jira-backup

## Usage

See [HOW_TO_USE.md](HOW_TO_USE.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/denvazh/jira-backup.

