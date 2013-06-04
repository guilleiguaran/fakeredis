require 'spec_helper'

module FakeRedis
  describe "SetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a set" do
      @client.sadd("key", "value").should be == true
      @client.sadd("key", "value").should be == false

      @client.smembers("key").should be == ["value"]
    end

    it "should raise error if command arguments count is not enough" do
      expect { @client.sadd("key", []) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'sadd' command")

      @client.smembers("key").should be_empty
    end

    it "should add multiple members to a set" do
      @client.sadd("key", %w(value other something more)).should be == 4
      @client.sadd("key", %w(and additional values)).should be == 3
      @client.smembers("key").should =~ ["value", "other", "something", "more", "and", "additional", "values"]
    end

    it "should get the number of members in a set" do
      @client.sadd("key", "val1")
      @client.sadd("key", "val2")

      @client.scard("key").should be == 2
    end

    it "should subtract multiple sets" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")

      @client.sdiff("key1", "key2", "key3").should =~ ["b", "d"]
    end

    it "should subtract multiple sets and store the resulting set in a key" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")
      @client.sdiffstore("key", "key1", "key2", "key3")

      @client.smembers("key").should =~ ["b", "d"]
    end

    it "should intersect multiple sets" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")

      @client.sinter("key1", "key2", "key3").should be == ["c"]
    end

    it "should intersect multiple sets and store the resulting set in a key" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")
      @client.sinterstore("key", "key1", "key2", "key3")
      @client.smembers("key").should be == ["c"]
    end

    it "should determine if a given value is a member of a set" do
      @client.sadd("key1", "a")

      @client.sismember("key1", "a").should be == true
      @client.sismember("key1", "b").should be == false
      @client.sismember("key2", "a").should be == false
    end

    it "should get all the members in a set" do
      @client.sadd("key", "a")
      @client.sadd("key", "b")
      @client.sadd("key", "c")
      @client.sadd("key", "d")

      @client.smembers("key").should =~ ["a", "b", "c", "d"]
    end

    it "should move a member from one set to another" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key2", "c")
      @client.smove("key1", "key2", "a").should be == true
      @client.smove("key1", "key2", "a").should be == false

      @client.smembers("key1").should be == ["b"]
      @client.smembers("key2").should =~ ["c", "a"]
    end

    it "should remove and return a random member from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")

      ["a", "b"].include?(@client.spop("key1")).should be_true
      ["a", "b"].include?(@client.spop("key1")).should be_true
      @client.spop("key1").should be_nil
    end

    it "should get a random member from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")

      ["a", "b"].include?(@client.spop("key1")).should be_true
    end

    it "should remove a member from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.srem("key1", "a").should be == true
      @client.srem("key1", "a").should be == false

      @client.smembers("key1").should be == ["b"]
    end

    it "should remove the set's key once it's empty" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.srem("key1", "b")
      @client.srem("key1", "a")

      @client.exists("key1").should be == false
    end

    it "should add multiple sets" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")

      @client.sunion("key1", "key2", "key3").should =~ ["a", "b", "c", "d", "e"]
    end

    it "should add multiple sets and store the resulting set in a key" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")
      @client.sunionstore("key", "key1", "key2", "key3")

      @client.smembers("key").should =~ ["a", "b", "c", "d", "e"]
    end
  end
end
