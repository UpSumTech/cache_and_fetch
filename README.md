# CacheAndFetch

A simple gem that allows to add a soft expiry to your cache.
If your cache soft expires, you get the stale record to work with,
while it fetches the fresh record from the source in background.

## Build status

[![Build Status](https://travis-ci.org/sumanmukherjee03/cache_and_fetch.png)](https://travis-ci.org/sumanmukherjee03/cache_and_fetch)

## Installation

Add this line to your application's Gemfile:

    gem 'cache_man'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cache_man

## Usage

```ruby
  class Test < ActiveResource::Base
    include CacheAndFetch::Fetchable
  end

  Test.fetch(1) # when invoked the first time, goes and fetches the resource from a remote location.
  # After sometime we try to fetch the resource again
  Test.fetch(1) # will return the value from the cache
  # As of now, the soft expiration for the cache is hard coded to 20 mins
  # We assume that your Rails cache expires after that
  # After 20 mins
  Test.fetch(1) # Still return the cached data, but spins an sysnc process to fetch the fresh data
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
Copyright (c) 2013 Suman Mukherjee

MIT License

For more information on license, please look at LICENSE.txt
