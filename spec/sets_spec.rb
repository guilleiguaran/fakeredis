require 'spec_helper'

module FakeRedis
  describe "SetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a set" do
      @client.sadd("key", "value").should == true
      @client.sadd("key", "value").should == false

      @client.smembers("key").should == ["value"]
    end

    it "should add multiple members to a set" do
      @client.sadd("key", %w(value other something more)).should == 4
      @client.smembers("key").should =~ ["value", "other", "something", "more"]
    end

    it "should get the number of members in a set" do
      @client.sadd("key", "val1")
      @client.sadd("key", "val2")

      @client.scard("key").should == 2
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

      @client.sinter("key1", "key2", "key3").should == ["c"]
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
      @client.smembers("key").should == ["c"]
    end

    it "should determine if a given value is a member of a set" do
      @client.sadd("key1", "a")

      @client.sismember("key1", "a").should == true
      @client.sismember("key1", "b").should == false
      @client.sismember("key2", "a").should == false
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
      @client.smove("key1", "key2", "a").should == true
      @client.smove("key1", "key2", "a").should == false

      @client.smembers("key1").should == ["b"]
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
      @client.srem("key1", "a").should == true
      @client.srem("key1", "a").should == false

      @client.smembers("key1").should == ["b"]
    end

    it "should remove the set's key once it's empty" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.srem("key1", "b")
      @client.srem("key1", "a")

      @client.exists("key1").should == false
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
