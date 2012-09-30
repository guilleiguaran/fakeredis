require 'spec_helper'

module FakeRedis
  describe "StringsMethods" do

    before(:each) do
      @client = Redis.new
    end

    it "should append a value to key" do
      @client.set("key1", "Hello")
      @client.append("key1", " World")

      @client.get("key1").should be == "Hello World"
    end

    it "should decrement the integer value of a key by one" do
      @client.set("counter", "1")
      @client.decr("counter")

      @client.get("counter").should be == "0"
    end

    it "should decrement the integer value of a key by the given number" do
      @client.set("counter", "10")
      @client.decrby("counter", "5")

      @client.get("counter").should be == "5"
    end

    it "should get the value of a key" do
      @client.get("key2").should be == nil
    end

    it "should returns the bit value at offset in the string value stored at key" do
      @client.set("key1", "a")

      @client.getbit("key1", 1).should be == 1
      @client.getbit("key1", 2).should be == 1
      @client.getbit("key1", 3).should be == 0
      @client.getbit("key1", 4).should be == 0
      @client.getbit("key1", 5).should be == 0
      @client.getbit("key1", 6).should be == 0
      @client.getbit("key1", 7).should be == 1
    end

    it "should allow direct bit manipulation even if the string isn't set" do
      @client.setbit("key1", 10, 1)
      @client.getbit("key1", 10).should be == 1
    end

    it "should get a substring of the string stored at a key" do
      @client.set("key1", "This a message")

      @client.getrange("key1", 0, 3).should be == "This"
      @client.substr("key1", 0, 3).should be == "This"
    end

    it "should set the string value of a key and return its old value" do
      @client.set("key1","value1")

      @client.getset("key1", "value2").should be == "value1"
      @client.get("key1").should be == "value2"
    end

    it "should return nil for #getset if the key does not exist when setting" do
      @client.getset("key1", "value1").should be == nil
      @client.get("key1").should be == "value1"
    end

    it "should increment the integer value of a key by one" do
      @client.set("counter", "1")
      @client.incr("counter").should be == 2

      @client.get("counter").should be == "2"
    end

    it "should not change the expire value of the key during incr" do
      @client.set("counter", "1")
      @client.expire("counter", 600).should be_true
      @client.ttl("counter").should be == 600
      @client.incr("counter").should be == 2
      @client.ttl("counter").should be == 600
    end

    it "should decrement the integer value of a key by one" do
      @client.set("counter", "1")
      @client.decr("counter").should be == 0

      @client.get("counter").should be == "0"
    end

    it "should not change the expire value of the key during decr" do
      @client.set("counter", "2")
      @client.expire("counter", 600).should be_true
      @client.ttl("counter").should be == 600
      @client.decr("counter").should be == 1
      @client.ttl("counter").should be == 600
    end

    it "should increment the integer value of a key by the given number" do
      @client.set("counter", "10")
      @client.incrby("counter", "5").should be == 15
      @client.incrby("counter", 2).should be == 17
      @client.get("counter").should be == "17"
    end

    it "should not change the expire value of the key during incrby" do
      @client.set("counter", "1")
      @client.expire("counter", 600).should be_true
      @client.ttl("counter").should be == 600
      @client.incrby("counter", "5").should be == 6
      @client.ttl("counter").should be == 600
    end

    it "should decrement the integer value of a key by the given number" do
      @client.set("counter", "10")
      @client.decrby("counter", "5").should be == 5
      @client.decrby("counter", 2).should be == 3
      @client.get("counter").should be == "3"
    end

    it "should not change the expire value of the key during decrby" do
      @client.set("counter", "8")
      @client.expire("counter", 600).should be_true
      @client.ttl("counter").should be == 600
      @client.decrby("counter", "3").should be == 5
      @client.ttl("counter").should be == 600
    end

    it "should get the values of all the given keys" do
      @client.set("key1", "value1")
      @client.set("key2", "value2")
      @client.set("key3", "value3")

      @client.mget("key1", "key2", "key3").should be == ["value1", "value2", "value3"]
    end

    it 'raises an argument error when not passed any fields' do
      @client.set("key3", "value3")

      lambda { @client.mget }.should raise_error(Redis::CommandError)
    end

    it "should set multiple keys to multiple values" do
      @client.mset(:key1, "value1", :key2, "value2")

      @client.get("key1").should be == "value1"
      @client.get("key2").should be == "value2"
    end

    it "should set multiple keys to multiple values, only if none of the keys exist" do
      @client.msetnx(:key1, "value1", :key2, "value2").should be == true
      @client.msetnx(:key1, "value3", :key2, "value4").should be == false

      @client.get("key1").should be == "value1"
      @client.get("key2").should be == "value2"
    end

    it "should set multiple keys to multiple values with a hash" do
      @client.mapped_mset(:key1 => "value1", :key2 => "value2")

      @client.get("key1").should be == "value1"
      @client.get("key2").should be == "value2"
    end

    it "should set multiple keys to multiple values with a hash, only if none of the keys exist" do
      @client.mapped_msetnx(:key1 => "value1", :key2 => "value2").should be == true
      @client.mapped_msetnx(:key1 => "value3", :key2 => "value4").should be == false

      @client.get("key1").should be == "value1"
      @client.get("key2").should be == "value2"
    end

    it "should set the string value of a key" do
      @client.set("key1", "1")

      @client.get("key1").should be == "1"
    end

    it "should sets or clears the bit at offset in the string value stored at key" do
      @client.set("key1", "abc")
      @client.setbit("key1", 11, 1)

      @client.get("key1").should be == "arc"
    end

    it "should set the value and expiration of a key" do
      @client.setex("key1", 30, "value1")

      @client.get("key1").should be == "value1"
      @client.ttl("key1").should be == 30
    end

    it "should set the value of a key, only if the key does not exist" do
      @client.set("key1", "test value")
      @client.setnx("key1", "new value")
      @client.setnx("key2", "another value")

      @client.get("key1").should be == "test value"
      @client.get("key2").should be == "another value"
    end

    it "should overwrite part of a string at key starting at the specified offset" do
      @client.set("key1", "Hello World")
      @client.setrange("key1", 6, "Redis")

      @client.get("key1").should be == "Hello Redis"
    end

    it "should get the length of the value stored in a key" do
      @client.set("key1", "abc")

      @client.strlen("key1").should be == 3
    end

  end
end
