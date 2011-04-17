require 'spec_helper'

module FakeRedis
  describe "StringsMethods" do

    before(:each) do
      @client = FakeRedis::Redis.new
    end

    it "should append a value to key" do
      @client.set("key1", "Hello")
      @client.append("key1", " World")

      @client.get("key1").should == "Hello World"
    end

    it "should decrement the integer value of a key by one" do
      @client.set("counter", "1")
      @client.decr("counter")

      @client.get("counter").should == "0"
    end

    it "should decrement the integer value of a key by the given number" do
      @client.set("counter", "10")
      @client.decrby("counter", "5")

      @client.get("counter").should == "5"
    end

    it "should get the value of a key" do
      @client.get("key2").should == nil
    end

    it "should returns the bit value at offset in the string value stored at key" do
      @client.set("key1", "a")

      @client.getbit("key1", 1).should == "1"
      @client.getbit("key1", 2).should == "1"
      @client.getbit("key1", 3).should == "0"
      @client.getbit("key1", 4).should == "0"
      @client.getbit("key1", 5).should == "0"
      @client.getbit("key1", 6).should == "0"
      @client.getbit("key1", 7).should == "1"
    end

    it "should get a substring of the string stored at a key" do
      @client.set("key1", "This a message")

      @client.getrange("key1", 0, 3).should == "This"
    end

    it "should set the string value of a key and return its old value" do
      @client.set("key1","value1")

      @client.getset("key1", "value2").should == "value1"
      @client.get("key1").should == "value2"
    end

      it "should increment the integer value of a key by one" do
      @client.set("counter", "1")
      @client.incr("counter")

      @client.get("counter").should == "2"
    end

    it "should increment the integer value of a key by the given number" do
      @client.set("counter", "10")
      @client.incrby("counter", "5")

      @client.get("counter").should == "15"
    end

    it "should get the values of all the given keys" do
      @client.set("key1", "value1")
      @client.set("key2", "value2")
      @client.set("key3", "value3")

      @client.mget("key1", "key2", "key3").should == ["value1", "value2", "value3"]
    end

    it "should get the values of all the given keys mapped" do
      @client.set("key1", "value1")
      @client.set("key2", "value2")
      @client.set("key3", "value3")
      response = @client.mapped_mget("key1", "key2", "key3")

      response["key1"].should == "value1"
      response["key2"].should == "value2"
      response["key3"].should == "value3"
    end

    it "should set multiple keys to multiple values" do
      @client.mset(:key1, "value1", :key2, "value2")

      @client.get("key1").should == "value1"
      @client.get("key2").should == "value2"
    end

    it "should set multiple keys to multiple values, only if none of the keys exist" do
      @client.msetnx(:key1, "value1", :key2, "value2")
      @client.msetnx(:key1, "value3", :key2, "value4")

      @client.get("key1").should == "value1"
      @client.get("key2").should == "value2"
    end

    it "should set the string value of a key" do
      @client.set("key1", "1")

      @client.get("key1").should == "1"
    end

    it "should sets or clears the bit at offset in the string value stored at key" do
      @client.set("key1", "abc")
      @client.setbit("key1", 11, 1)

      @client.get("key1").should == "arc"
    end

    it "should set the value and expiration of a key" do
      @client.setex("key1", 30, "value1")

      @client.get("key1").should == "value1"
      @client.ttl("key1").should == 30
    end

    it "should set the value of a key, only if the key does not exist" do
      @client.set("key1", "test value")
      @client.setnx("key1", "new value")
      @client.setnx("key2", "another value")

      @client.get("key1").should == "test value"
      @client.get("key2").should == "another value"
    end

    it "should overwrite part of a string at key starting at the specified offset" do
      @client.set("key1", "Hello World")
      @client.setrange("key1", 6, "Redis")

      @client.get("key1").should == "Hello Redis"
    end

    it "should get the length of the value stored in a key" do
      @client.set("key1", "abc")

      @client.strlen("key1").should == 3
    end

  end
end
