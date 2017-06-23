# Radagen

[![Build Status](https://travis-ci.org/smidas/radagen.svg?branch=master)](https://travis-ci.org/smidas/radagen)

Radagen is a psuedo random data generator library for the Ruby language and was build with two primary design goals: *composition* and *sizing*. These two properties allow this library to be used in a range of different applications from simple test data generation, model checking, fuzz testing, database seeding to the foundation of generative/property based testing frameworks.

Radagen was greatly influenced by the generator API found in [test.check](https://github.com/clojure/test.check) and shares many of the same naming conventions. In contrast however Radagen attemps to separate the idea of *shrinking* (the simplification of values) from the generators themselves. We will see how well this plays out :)

## Requirements
- Ruby 2.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'radagen'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install radagen

## API Documentation

## Usage

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt with pry that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/smidas/radagen.

## TODO
- Explore and implement the need for a splittable PRNG.
- Simple usage documentation
- Implement a Bignum generator with a good enough distribution.

## License

Radagen is released under the [MIT License](https://github.com/smidas/radagen/blob/master/LICENSE).