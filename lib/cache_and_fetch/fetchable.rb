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
          resource.recache if resource.stale?
        else
          resource = cache(id)
        end
        resource
      end
    end
  end
end
