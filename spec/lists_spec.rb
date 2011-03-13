require 'spec_helper'

module FakeRedis
  describe "ListsMethods" do
    before(:each) do
      @client = FakeRedis::Redis.new
    end

    it "should get an element from a list by its index" do
      @client.lpush("key1", "val1")
      @client.lpush("key1", "val2")

      @client.lindex("key1", 0).should == "val2"
      @client.lindex("key1", -1).should == "val1"
      @client.lindex("key1", 3).should == nil
    end

    it "should insert an element before or after another element in a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v3")
      @client.linsert("key1", :before, "v3", "v2")

      @client.lrange("key1", 0, -1).should == ["v1", "v2", "v3"]
    end

    it "should get the length of a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")

      @client.llen("key1").should == 2
      @client.llen("key2").should == 0
    end

    it "should remove and get the first element in a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v3")

      @client.lpop("key1").should == "v1"
      @client.lrange("key1", 0, -1).should == ["v2", "v3"]
    end

    it "should prepend a value to a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")

      @client.lrange("key1", 0, -1).should == ["v1", "v2"]
    end

    it "should prepend a value to a list, only if the list exists" do
      @client.lpush("key1", "v1")

      @client.lpushx("key1", "v2")
      @client.lpushx("key2", "v3")

      @client.lrange("key1", 0, -1).should == ["v2", "v1"]
      @client.llen("key2").should == 0
    end

    it "should get a range of elements from a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v3")

      @client.lrange("key1", 1, -1).should == ["v2", "v3"]
    end

    it "should remove elements from a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v1")

      @client.lrem("key1", 1, "v1").should == 1
      @client.lrem("key1", -2, "v2").should == 2
    end

    it "should set the value of an element in a list by its index"

    it "should trim a list to the specified range"

    it "should remove and get the last element in a list"

    it "should remove the last element in a list, append it to another list and return it"

    it "should append a value to a list"

    it "should append a value to a list, only if the list exists"
  end
end
