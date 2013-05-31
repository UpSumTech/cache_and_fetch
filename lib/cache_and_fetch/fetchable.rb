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
      def fetch(id)
        resource = get_cached(id)
        if resource
          if resource.stale?
            block_given? ? yield(resource) : resource.recache
          end
        else
          resource = cache(id)
        end
        resource
      end
    end
  end
end
