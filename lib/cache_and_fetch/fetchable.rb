module CacheAndFetch
  module Fetchable
    extend ActiveSupport::Concern

    included do
      include Cacheable
      begin
        extend "#{name}::Finder".constantize
      rescue NameError => ex
        raise FinderNotFound.new unless respond_to?(:find)
      end
      private_class_method :find
    end

    module ClassMethods
      def fetch(id)
        cached_resource = get_cached(id)
        if cached_resource
          cached_resource.recache_later if cached_resource.stale?
        else
          cached_resource = new_cache(id)
        end
        cached_resource
      end
    end
  end
end
