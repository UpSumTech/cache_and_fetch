module CacheAndFetch
  module Cacheable
    DEFAULT_CACHE_EXPIRY_TIME = 20.minutes

    extend ActiveSupport::Concern

    included do
      attr_accessor :cache_expires_at
    end

    module ClassMethods
      def cache_duration
        @cache_duration || set_cache_duration(Cacheable::DEFAULT_CACHE_EXPIRY_TIME)
      end

      def set_cache_duration(val)
        @cache_duration = val
      end

      def cache_client
        Rails.cache
      end

      def cache_key(id)
        "#{self.name.underscore}/#{id}"
      end

      def cache(id)
        resource = find(id)
        resource.cache
        resource
      end

      def get_cached(id)
        cache_client.read(cache_key(id))
      end
    end

    def cache_client
      self.class.cache_client
    end

    def cache_key
      self.class.cache_key(self.id)
    end

    def cache
      self.cache_expires_at = self.class.cache_duration.since.to_i
      self.cache_client.write(self.cache_key, self)
    end

    def stale?
      cache_expires_at && Time.now > Time.at(cache_expires_at)
    end

    def recache
      Rails.application.dispatch_publisher.publish(:subject => "recache_resource", :body => {:resource_type => self.class.name, :resource_id => self.id})
    end
  end
end
