module CacheAndFetch
  module Cacheable
    DEFAULT_CACHE_EXPIRY_TIME = 20.minutes
    DEFAULT_PRIMARY_KEY_METHOD = :id

    extend ActiveSupport::Concern

    included do
      attr_accessor :cache_expires_at
      unless self.respond_to?(:primary_key)
        instance_eval do
          def primary_key
            self.primary_key = Cacheable::DEFAULT_PRIMARY_KEY_METHOD unless @primary_key
            @primary_key
          end

          def primary_key=(val)
            @primary_key = val
          end
        end
      end
    end

    module ClassMethods
      def cache_duration
        self.cache_duration = Cacheable::DEFAULT_CACHE_EXPIRY_TIME unless @cache_duration
        @cache_duration
      end

      def cache_duration=(val)
        @cache_duration = val
      end

      def cache_client
        Rails.cache
      end

      def cache_key(p_key)
        "#{self.name.underscore}/#{p_key}"
      end

      def cache(p_key)
        resource = find(p_key)
        resource.cache
        resource
      end

      def get_cached(p_key)
        cache_client.read(cache_key(p_key))
      end
    end

    def cache_client
      self.class.cache_client
    end

    def cache_key
      self.class.cache_key(self.__send__(self.class.primary_key))
    end

    def cache
      self.cache_expires_at = self.class.cache_duration.since.to_i
      self.cache_client.write(self.cache_key, self)
    end

    def stale?
      cache_expires_at && Time.now > Time.at(cache_expires_at)
    end

    def recache
      Thread.new do
        p_key = self.__send__(self.class.primary_key)
        self.class.__send__(:find, p_key).cache
      end
    end
  end
end
