require 'spec_helper'

module FakeRedis
  describe "KeysMethods" do

    before(:each) do
      @client = FakeRedis::Redis.new
    end

    it "should delete values" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.del("key1", "key2")

      @client.get("key1").should == nil
    end

    it "should respond if a key exist" do
      @client.set("key1", "1")

      @client.exists("key1").should == true
      @client.exists("key2").should == false
    end

    it "should set a expire ttl of a key" do
      @client.set("key1", "1")
      @client.expire("key1", 1)

      @client.ttl("key1").should == 1
    end

    it "should set a expire timestamp of a key" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)

      @client.ttl("key1").should == 1
    end

    it "should get multiple values" do
      @client.set("key:a", "1")
      @client.set("key:b", "2")
      @client.set("key:c", "3")
      @client.set("akeyd", "4")
      @client.set("key1", "5")

      @client.keys("key:").should == ["key:a", "key:b", "key:c"]
    end

    it "should persist a value" do
      @client.set("key1", "1")
      @client.persist("key1")

      @client.ttl("key1").should == -1
    end

    it "should get a random value" do
      @client.set("key1", "1")
      @client.set("key2", "2")

      ["key1", "key2"].include?(@client.randomkey).should == true
    end

    it "should rename a key" do
      @client.set("key1", "2")
      @client.rename("key1", "key2")

      @client.get("key1").should == nil
      @client.get("key2").should == "2"
    end

    it "should rename a key if new name doesn't exist" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key3", "3")
      @client.renamenx("key1", "key2")
      @client.renamenx("key3", "key4")

      @client.get("key1").should == "1"
      @client.get("key2").should == "2"
      @client.get("key3").should == nil
      @client.get("key4").should == "3"
    end

    it "should sort the values of a key" do
      pending "SORT Command not implemented yet"
    end

    it "should return the type of a value" do
      @client.set("key1", "1")

      @client.type("key1").should == "string"
      @client.type("key0").should == "none"
    end
  end
end
