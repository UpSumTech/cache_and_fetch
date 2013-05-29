require "cache_and_fetch/version"
require "active_support/concern"
require "active_support/core_ext/numeric/time"
require "rails"

module CacheAndFetch
end

require "cache_and_fetch/errors.rb"
require "cache_and_fetch/cacheable"
require "cache_and_fetch/fetchable"
