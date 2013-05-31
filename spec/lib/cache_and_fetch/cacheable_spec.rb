require 'spec_helper'

describe CacheAndFetch::Cacheable do
  class CacheableTestDummy
    include CacheAndFetch::Cacheable
    attr_accessor :id

    def initialize(attrs = {})
      attrs.each do |(key, val)|
        self.__send__("#{key.to_s}=".to_sym, val)
      end
    end

    def self.find(id)
      self.new(:id => id)
    end

    def attributes
      {:id => id}
    end

    def ==(other)
      other.respond_to?(:attributes) && attributes == other.attributes
    end
  end

  subject do
    CacheableTestDummy.new(:id => 1)
  end

  describe "cache_duration" do
    it "should return the duration for which the cache is valid" do
      CacheAndFetch::Cacheable.cache_duration.should eq(20.minutes)
    end
  end

  describe ".cache_client" do
    it "should return a client to access the cache" do
      client = CacheableTestDummy.cache_client
      client.should respond_to(:read)
      client.should respond_to(:write)
    end
  end

  describe ".cache_key" do
    it "should return the key where the cached value is stored" do
      CacheableTestDummy.cache_key(subject.id).should eq('cacheable_test_dummy/1')
    end
  end

  describe ".cache" do
    it "should find the object and cache it" do
      CacheableTestDummy.cache(subject.id)
      result = CacheableTestDummy.cache_client.read('cacheable_test_dummy/1')
      result.should_not be_stale
      result.should eq(subject)
    end
  end

  describe "get_cached" do
    before :each do
      CacheableTestDummy.cache(subject.id)
    end

    it "returns the cached resource" do
      CacheableTestDummy.get_cached(subject.id).should_not be_nil
    end
  end

  describe "#cache_client" do
    it "should return a client to access the cache" do
      client = subject.cache_client
      client.should respond_to(:read)
      client.should respond_to(:write)
    end
  end

  describe "#cache_key" do
    it "should return the key where the cached value is stored" do
      subject.cache_key.should eq('cacheable_test_dummy/1')
    end
  end

  describe "#cache" do
    it "should cache the object with a soft expiry time" do
      subject.cache
      result = CacheableTestDummy.cache_client.read('cacheable_test_dummy/1')
      result.should_not be_stale
      result.should eq(subject)
    end
  end

  describe "#stale?" do
    context "when the object got cached" do
      before :each do
        CacheableTestDummy.cache(subject.id)
      end

      context "when the cache has soft expired" do
        before :each do
          subject.cache_expires_at = Time.now
        end

        it "returns true" do
          subject.should be_stale
        end
      end

      context "when the cache has not soft expired" do
        it "returns false" do
          subject.should_not be_stale
        end
      end
    end

    context "when the object is not cached" do
      it "returns false" do
        subject.should_not be_stale
      end
    end
  end
end
