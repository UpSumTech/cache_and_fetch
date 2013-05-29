require 'spec_helper'

describe CacheAndFetch::Fetchable do
  class FetchableResource < ActiveResource::Base
    include CacheAndFetch::Fetchable
    self.site = 'http://test.example.com'
  end

  let :publisher do
    Rails.application.dispatch_publisher
  end

  describe ".included" do
    context "when the class including the module does not have a custom finder" do
      it "should raise an error" do
        expect do
          Class.new do
            include CacheAndFetch::Fetchable
          end
        end.to raise_exception(CacheAndFetch::FinderNotFound)
      end
    end

    context "when the class including the module has a custom finder" do
      before :each do
        class PatheticFetchableDummy < ActiveResource::Base
          self.site = 'http://test.example.com'
        end

        module PatheticFetchableDummy::Finder
          def find(key)
            "mutilated-#{key.to_s}"
          end
        end
      end

      it "should not raise any exception and use the custom finder" do
        expect do
          class PatheticFetchableDummy
            include CacheAndFetch::Fetchable
          end
        end.to_not raise_exception

        PatheticFetchableDummy.send(:find, 'body').should eq('mutilated-body')
      end
    end
  end

  describe ".find" do
    it "should throw an error" do
      expect { FetchableResource.find(1) }.to raise_exception(NoMethodError)
    end
  end

  describe ".fetch" do
    context "when the object does not exist in the cache" do
      before :each do
        stub_request(:get, "http://test.example.com/fetchable_resources/1.json") \
          .with(:headers => {'Accept'=>'application/json'}) \
          .to_return(:status => 200, :body => {'id' => 1, 'name' => 'test'}.to_json, :headers => {})
      end

      it "should fetch the object from the remote application" do
        obj = FetchableResource.fetch(1)
        obj.id.should eq(1)
        obj.name.should eq('test')
      end
    end

    context "when the object already exists in the cache" do
      context "when the cache has not yet expired" do
        before :each do
          @obj = FetchableResource.new(:id => 1, :name => 'test')
          @obj.instance_variable_set("@cache_expires_at", 10.minutes.since.to_i)
          FetchableResource.cache_client.write('fetchable_resource/1', @obj)
        end

        it "should fetch the object from the cache" do
          publisher.should_receive(:publish).exactly(0).times
          FetchableResource.fetch(1).should eq(@obj)
        end
      end

      context "when the cache has expired" do
        before :each do
          stub_request(:get, "http://test.example.com/fetchable_resources/1.json") \
            .with(:headers => {'Accept'=>'application/json'}) \
            .to_return(:status => 200, :body => {'id' => 1, 'name' => 'test'}.to_json, :headers => {})
          @obj = FetchableResource.new(:id => 1, :name => 'test')
          @obj.instance_variable_set("@cache_expires_at",  10.minutes.ago.to_i)
          FetchableResource.cache_client.write('fetchable_resource/1', @obj)
        end

        it "should fetch the object from the cache" do
          catch(:publish_was_called) { result = FetchableResource.fetch(1).should eq(@obj) }
        end

        it "should enqueue a message with the messaging system to fetch the resource asynchronously" do
          catch(:publish_was_called) { FetchableResource.fetch(1) }.should eq({:subject => "recache_resource", :body => {:resource_type => "FetchableResource", :resource_id => 1}})
        end
      end
    end
  end
end
