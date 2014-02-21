require 'spec_helper'

describe CacheAndFetch::Fetchable do
  class FetchableResource < ActiveResource::Base
    include CacheAndFetch::Fetchable
    register_cache_client Rails.cache
    self.site = 'http://test.example.com'
  end

  describe "custom finder" do
    before :each do
      module Finder
        def find(key)
          "mutilated-#{key.to_s}"
        end
      end

      class PatheticFetchableDummy < ActiveResource::Base
        self.site = 'http://test.example.com'
        include CacheAndFetch::Fetchable
        register_cache_client Rails.cache
        register_finder Finder
      end
    end

    it "finds the cached content" do
      PatheticFetchableDummy.send(:find, 'body').should eq('mutilated-body')
    end
  end

  describe ".fetch" do
    context "when the object does not exist in the cache" do
      before :each do
        stub_request(:get, "http://test.example.com/fetchable_resources/1.json") \
          .with(:headers => {'Accept'=>'application/json'}) \
          .to_return(:status => 200, :body => {'id' => 1, 'name' => 'test'}.to_json, :headers => {})
      end

      it "fetches the object from the remote application" do
        obj = FetchableResource.fetch(1)
        obj.id.should eq(1)
        obj.name.should eq('test')
      end
    end

    context "when the object already exists in the cache" do
      context "when the cache has not yet expired" do
        before :each do
          @obj = FetchableResource.new(:id => 1, :name => 'test')
          @obj.cache
        end

        it "fetches the object from the cache" do
          FetchableResource.fetch(1).should eq(@obj)
        end
      end

      context "when the cache has expired" do
        before :each do
          @obj = FetchableResource.new(:id => 1, :name => 'test')
          @obj.cache_expires_at = 10.minutes.ago.to_i
          FetchableResource.cache_client.write('fetchable_resource/1', @obj)
        end

        context "when the fetch method receives no custom block" do
          before :each do
            stub_request(:get, "http://test.example.com/fetchable_resources/1.json") \
              .with(:headers => {'Accept'=>'application/json'}) \
              .to_return(:status => 200, :body => {'id' => 1, 'name' => 'another_test'}.to_json, :headers => {})
          end

          it "fetches the object from the cache" do
            FetchableResource.fetch(1).should eq(@obj)
          end

          it "recaches the object" do
            FetchableResource.fetch(1).name.should eq('test')
            sleep 1
            FetchableResource.fetch(1).name.should eq('another_test')
          end
        end

        context "when the fetch method receives a custom block" do
          it "fetches the object from the cache" do
            catch(:foo) do
              FetchableResource.fetch(1) do |resource|
                throw :foo
              end.should eq(@obj)
            end
          end
        end
      end
    end
  end
end
