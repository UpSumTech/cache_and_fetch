$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "rails"
require "active_resource"
require "webmock/rspec"
require "cache_and_fetch"

module CacheAndFetch
  Struct.new('Publisher') do
    def publish(options)
      throw :publish_was_called, options
    end
  end

  class Application < ::Rails::Application
    def dispatch_publisher
      Struct::Publisher.new
    end
  end
end

CacheAndFetch::Application.initialize!

RSpec.configure do |config|
  config.before do
    Rails.cache.clear
  end

  config.mock_with :rspec
  config.order = 'random'
  config.color_enabled = true
  config.tty = true
end
