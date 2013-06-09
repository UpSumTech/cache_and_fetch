# CacheAndFetch

A simple gem that allows to add a soft expiry to your cache.
If your cache soft expires, you get the stale record to work with,
while it fetches the fresh record from the source in background.

[![Gem Version](https://badge.fury.io/rb/cache_and_fetch.png)](http://badge.fury.io/rb/cache_and_fetch)
[![Build Status](https://travis-ci.org/sumanmukherjee03/cache_and_fetch.png)](https://travis-ci.org/sumanmukherjee03/cache_and_fetch)
[![Dependency Status](https://gemnasium.com/sumanmukherjee03/cache_and_fetch.png)](https://gemnasium.com/sumanmukherjee03/cache_and_fetch)
[![Code Climate](https://codeclimate.com/github/sumanmukherjee03/cache_and_fetch.png)](https://codeclimate.com/github/sumanmukherjee03/cache_and_fetch)
[![Coverage Status](https://coveralls.io/repos/sumanmukherjee03/cache_and_fetch/badge.png)](https://coveralls.io/r/sumanmukherjee03/cache_and_fetch)

## Installation

Add this line to your application's Gemfile:

    gem 'cache_and_fetch'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cache_and_fetch

## Usage

```ruby
  class Test < ActiveResource::Base
    self.site = 'http://test.example.com'
    include CacheAndFetch::Fetchable
  end
```

You can set a custom cache expiration limit for the class. If this is not set, the soft cache expires after 20 minutes by default.
```ruby
    self.cache_expiration = 10.minutes
```

When invoked for the first time(cold cache), the gem goes and fetches the resource from a remote location.
```ruby
  Test.fetch(1) # #<Test:0x007f8e33daf980 @attributes={"id"=>1, "name"=>"test"}, @prefix_options={}, @persisted=true, @cache_expires_at=1370049015>
```

After sometime, let's say the resource has updated it's name to 'new test'.
However, the soft cache has not yet expired.
When we try to fetch the resource again, it returns the cached value.
```ruby
  Test.fetch(1) # #<Test:0x007f8e33daf980 @attributes={"id"=>1, "name"=>"test"}, @prefix_options={}, @persisted=true, @cache_expires_at=1370049015>
```

After 10 mins, when we try to fetch the record again, it returns the value from the cache.
But spins off an async process, to fetch the fresh resource and update the cache.
```ruby
  Test.fetch(1) # #<Test:0x007f8e33daf980 @attributes={"id"=>1, "name"=>"test"}, @prefix_options={}, @persisted=true, @cache_expires_at=1370049015>
```
 
When we try to fetch the record again next time, it gives us the new data which is now in the cache.
```ruby
  Test.fetch(1) # #<Test:0x007f8e33daf980 @attributes={"id"=>1, "name"=>"new test"}, @prefix_options={}, @persisted=true, @cache_expires_at=1370049915>
```

If the default async fetching is not prefered, you can pass a custom block to fetch the fresh data.
```ruby
  Test.fetch(1) do |resource|
    resource.delay(:queue => 'caching').recache # This example is using delayed_jobs
  end
```

The gem however works for any class that responds to a class level 'find' method.
However, it allows one the flexibility to define a custom Finder module.
The gem automatically extends the class with the custom finder module.

In the following example, notice how the class does not inherit ActiveResource::Base.
```ruby
class SimpleTest
  include CacheAndFetch::Fetchable

  attr_accessor :id

  def initialize(id)
    @id = id
  end
end
```

A finder module needs to be defined with it's name as <class_name>Finder.
The class SimpleTest will get extended by this module. The logic of find
can either call a remote web service or even fetch it from a database.
```ruby
module SimpleTest::Finder
  def find(id)
    response = HTTParty.get("http://example.com/simple_tests/#{id}.json") # This example uses httparty
    self.new(response.body)
  end
end
```

The gem allows you to set the method name you want to use as primary key.
Of course, your instance must respond to the method you have set to extract the primary key.
```ruby
class AnotherTest
  include CacheAndFetch::Fetchable

  attr_accessor :guid

  self.primary_key = :guid

  def initialize(guid)
    @guid = guid
  end
end
```
So, now when you do a ```Test.fetch(1)```, the argument for fetch
represents the primary key of the object. In this case, it is the guid
of the object.

The gem makes use of Rails caching mechanism.
Hence, it only works with Rails as of now.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. Or update documentation

## License
Copyright (c) 2013 Suman Mukherjee

MIT License

For more information on license, please look at LICENSE.txt
