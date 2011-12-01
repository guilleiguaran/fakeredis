require 'spec_helper'

module FakeRedis
  describe "SortedSetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a sorted set, or update its score if it already exists" do
      @client.zadd("key", 1, "val").should be(true)
      @client.zscore("key", "val").should == 1

      @client.zadd("key", 2, "val").should be(false)
      @client.zscore("key", "val").should == 2
    end

    it "should remove members from sorted sets" do
      @client.zrem("key", "val").should be(false)
      @client.zadd("key", 1, "val").should be(true)
      @client.zrem("key", "val").should be(true)
    end

    it "should get the number of members in a sorted set" do
      @client.zadd("key", 1, "val2")
      @client.zadd("key", 2, "val1")
      @client.zadd("key", 5, "val3")

      @client.zcard("key").should == 3
    end

    it "should count the members in a sorted set with scores within the given values" do
      @client.zadd("key", 1, "val1")
      @client.zadd("key", 2, "val2")
      @client.zadd("key", 3, "val3")

      @client.zcount("key", 2, 3).should == 2
    end

    it "should increment the score of a member in a sorted set" do
      @client.zadd("key", 1, "val1")
      @client.zincrby("key", 2, "val1").should == "3"
      @client.zscore("key", "val1").should == 3
    end

    #it "should intersect multiple sorted sets and store the resulting sorted set in a new key"

    it "should return a range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrange("key", 0, -1).should == ["one", "two", "three"]
      @client.zrange("key", 1, 2).should == ["two", "three"]
      @client.zrange("key", 0, -1, :withscores => true).should == ["one", "1", "two", "2", "three", "3"]
      @client.zrange("key", 1, 2, :with_scores => true).should == ["two", "2", "three", "3"]
    end

    it "should return a reversed range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrange("key", 0, -1).should == ["three", "two", "one"]
      @client.zrevrange("key", 1, 2).should == ["two", "one"]
      @client.zrevrange("key", 0, -1, :withscores => true).should == ["three", "3", "two", "2", "one", "1"]
      @client.zrevrange("key", 0, -1, :with_scores => true).should == ["three", "3", "two", "2", "one", "1"]
    end

    it "should return a range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrangebyscore("key", 0, 100).should == ["one", "two", "three"]
      @client.zrangebyscore("key", 1, 2).should == ["one", "two"]
      @client.zrangebyscore("key", 0, 100, :withscores => true).should == ["one", "1", "two", "2", "three", "3"]
      @client.zrangebyscore("key", 1, 2, :with_scores => true).should == ["one", "1", "two", "2"]
    end

    it "should return a reversed range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrangebyscore("key", 100, 0).should == ["three", "two", "one"]
      @client.zrevrangebyscore("key", 2, 1).should == ["two", "one"]
      @client.zrevrangebyscore("key", 1, 2).should == []
      @client.zrevrangebyscore("key", 2, 1, :with_scores => true).should == ["two", "2", "one", "1"]
    end

    it "should determine the index of a member in a sorted set" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrank("key", "three").should == 2
      @client.zrank("key", "four").should be_nil
    end

    it "should determine the reversed index of a member in a sorted set" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrank("key", "three").should == 0
      @client.zrevrank("key", "four").should be_nil
    end

    #it "should remove all members in a sorted set within the given indexes"

    #it "should remove all members in a sorted set within the given scores"

    #it "should return a range of members in a sorted set, by index, with scores ordered from high to low"

    #it "should return a range of members in a sorted set, by score, with scores ordered from high to low"

    #it "should determine the index of a member in a sorted set, with scores ordered from high to low"

    #it "should get the score associated with the given member in a sorted set"

    #it "should add multiple sorted sets and store the resulting sorted set in a new key"
  end
end
