module CacheAndFetch
  module Fetchable
    extend ActiveSupport::Concern
    include Cacheable

    module ClassMethods
      def register_finder(mod)
        self.extend(mod)
      end

      def fetch(p_key)
        resource = get_cached(p_key)
        if resource
          if resource.stale?
            block_given? ? yield(resource) : resource.recache
          end
        else
          resource = cache(p_key)
        end
        resource
      end
    end
  end
end
