# aws-rotate-keys

A simple gem to rotate your aws access keys.

[![Build
Status](https://travis-ci.org/pcreux/aws-rotate-keys.svg?branch=master)](https://travis-ci.org/pcreux/aws-rotate-keys)

[![Code
Climate](https://codeclimate.com/github/pcreux/aws-rotate-keys/badges/gpa.svg)](https://codeclimate.com/github/pcreux/aws-rotate-keys)

[![Test
Coverage](https://codeclimate.com/github/pcreux/aws-rotate-keys/badges/coverage.svg)](https://codeclimate.com/github/pcreux/aws-rotate-keys/coverage)


## Installation

    $ gem install aws-rotate-keys

## Usage

    $ aws-rotate-keys

That will:

1. connect to your aws account using `~/.aws/credentials` or environment variables
2. create a new access key
3. backup `~/.aws/credentials`
4. write the new key to `~/.aws/credentials`
5. delete your oldest access key from aws

Sample output:

```
Creating access key...
Writing new access key to ~/.aws/credentials
Deleting your oldest access key...
You're all set!
We've noticed that the environment variables AWS_ACCESS_KEY_ID and
AWS_SECRET_ACCESS_KEY are set.
Please remove them so that aws cli and libraries use ~/.aws/credentials
instead.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pcreux/aws-rotate-keys. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
