require 'spec_helper'

module FakeRedis
  describe "ConnectionMethods" do

    before(:each) do
      @client = Redis.new
    end

  if fakeredis?
    it "should authenticate to the server" do
      @client.auth("pass").should == "OK"
    end

    it "should re-use the same instance with the same host & port" do
      @client1 = Redis.new(:host => "localhost", :port => 1234)
      @client2 = Redis.new(:host => "localhost", :port => 1234)
      @client3 = Redis.new(:host => "localhost", :port => 5678)

      @client1.set("key1", "1")
      @client2.get("key1").should == "1"
      @client3.get("key1").should be_nil

      @client2.set("key2", "2")
      @client1.get("key2").should == "2"
      @client3.get("key2").should be_nil

      @client3.set("key3", "3")
      @client1.get("key3").should be_nil
      @client2.get("key3").should be_nil

      @client1.dbsize.should == 2
      @client2.dbsize.should == 2
      @client3.dbsize.should == 1
    end

    it "should connect to a specific database" do
      @client1 = Redis.new(:host => "localhost", :port => 1234, :db => 0)
      @client1.set("key1", "1")
      @client1.select(0)
      @client1.get("key1").should == "1"

      @client2 = Redis.new(:host => "localhost", :port => 1234, :db => 1)
      @client2.set("key1", "1")
      @client2.select(1)
      @client2.get("key1").should == "1"
    end
  end

    it "should not error with a disconnected client" do
      @client1 = Redis.new
      @client1.client.disconnect
      @client1.get("key1").should be_nil
    end

    it "should echo the given string" do
      @client.echo("something").should == "something"
    end

    it "should ping the server" do
      @client.ping.should == "PONG"
    end
  end
end
