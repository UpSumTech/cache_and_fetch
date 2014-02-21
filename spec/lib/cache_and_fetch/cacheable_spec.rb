require 'spec_helper'

describe CacheAndFetch::Cacheable do
  class CacheableTestDummy
    include CacheAndFetch::Cacheable
    register_cache_client Rails.cache

    attr_accessor :guid
    attr_accessor :name

    self.primary_key = :guid
    self.cache_duration = 25.minutes

    def initialize(attrs = {})
      attrs.each do |(key, val)|
        self.__send__("#{key.to_s}=".to_sym, val)
      end
    end

    def self.find(guid)
      self.new(:guid => guid)
    end

    def attributes
      {:guid => guid, :name => name}
    end

    def ==(other)
      other.respond_to?(:attributes) && attributes == other.attributes
    end
  end

  subject do
    CacheableTestDummy.new(:guid => 1)
  end

  describe ".primary_key" do
    after :each do
      CacheableTestDummy.primary_key = :guid
    end

    context "when the class including the module does not respond to the primary_key method" do
      context "when the primary key is set" do
        before :each do
          CacheableTestDummy.primary_key = :name
        end

        it "returns the symbolized method name of the primary key" do
          CacheableTestDummy.primary_key.should eq(:name)
        end
      end

      context "when the primary key is not set" do
        before :each do
          CacheableTestDummy.primary_key = nil
        end

        it "sets and returns the default primary key" do
          CacheableTestDummy.primary_key.should eq(described_class::DEFAULT_PRIMARY_KEY_METHOD)
        end
      end
    end
  end

  describe ".cache_duration" do
    after :each do
      CacheableTestDummy.cache_duration = 25.minutes
    end

    context "when the cache duration for soft expiry is set" do
      before :each do
        CacheableTestDummy.cache_duration = 15.minutes
      end

      it "returns the duration for which the cache is valid" do
        CacheableTestDummy.cache_duration.should eq(15.minutes)
      end
    end

    context "when the cache duration for soft expiry is not set" do
      before :each do
        CacheableTestDummy.cache_duration = nil
      end

      it "sets and returns the default cache duration" do
        CacheableTestDummy.cache_duration.should eq(described_class::DEFAULT_CACHE_EXPIRY_TIME)
      end
    end
  end

  describe ".cache_client" do
    it "returns a client to access the cache" do
      client = CacheableTestDummy.cache_client
      client.should respond_to(:read)
      client.should respond_to(:write)
    end
  end

  describe ".cache_key" do
    it "returns the key where the cached value is stored" do
      CacheableTestDummy.cache_key(subject.guid).should eq('cacheable_test_dummy/1')
    end
  end

  describe ".cache" do
    it "finds the object and cache it" do
      CacheableTestDummy.cache(subject.guid)
      result = CacheableTestDummy.cache_client.read('cacheable_test_dummy/1')
      result.should_not be_stale
      result.should eq(subject)
    end
  end

  describe "get_cached" do
    before :each do
      CacheableTestDummy.cache(subject.guid)
    end

    it "returns the cached resource" do
      CacheableTestDummy.get_cached(subject.guid).should_not be_nil
    end
  end

  describe "#cache_client" do
    it "returns a client to access the cache" do
      client = subject.cache_client
      client.should respond_to(:read)
      client.should respond_to(:write)
    end
  end

  describe "#cache_key" do
    it "returns the key where the cached value is stored" do
      subject.cache_key.should eq('cacheable_test_dummy/1')
    end
  end

  describe "#cache" do
    it "caches the object with a soft expiry time" do
      subject.cache
      result = CacheableTestDummy.cache_client.read('cacheable_test_dummy/1')
      result.should_not be_stale
      result.should eq(subject)
    end
  end

  describe "#stale?" do
    context "when the object got cached" do
      before :each do
        CacheableTestDummy.cache(subject.guid)
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
