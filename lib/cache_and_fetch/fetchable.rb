module CacheAndFetch
  module Fetchable
    extend ActiveSupport::Concern
    include Cacheable

    included do
      begin
        extend "#{name}::Finder".constantize
      rescue NameError => ex
        raise FinderNotFound.new unless respond_to?(:find)
      end
      private_class_method :find
    end

    module ClassMethods
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
