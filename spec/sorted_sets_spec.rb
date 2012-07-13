require 'spec_helper'

module FakeRedis
  describe "SortedSetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a sorted set, or update its score if it already exists" do
      @client.zadd("key", 1, "val").should be(true)
      @client.zscore("key", "val").should == 1.0

      @client.zadd("key", 2, "val").should be(false)
      @client.zscore("key", "val").should == 2.0
    end

    it "should add multiple members to a sorted set, or update its score if it already exists" do
      @client.zadd("key", [1, "val", 2, "val2"]).should be == 2
      @client.zscore("key", "val").should be == 1
      @client.zscore("key", "val2").should be == 2

      @client.zadd("key", [[5, "val"], [3, "val3"], [4, "val4"]]).should be == 2
      @client.zscore("key", "val").should be == 5
      @client.zscore("key", "val2").should be == 2
      @client.zscore("key", "val3").should be == 3
      @client.zscore("key", "val4").should be == 4
    end

    it "should error with wrong number of arguments when adding members" do
      -> { @client.zadd("key") }.should raise_error(ArgumentError, "wrong number of arguments")
      -> { @client.zadd("key", 1) }.should raise_error(ArgumentError, "wrong number of arguments")
      -> { @client.zadd("key", [1]) }.should raise_error(Redis::CommandError, "ERR wrong number of arguments for 'zadd' command")
      -> { @client.zadd("key", [1, "val", 2]) }.should raise_error(Redis::CommandError, "ERR syntax error")
      -> { @client.zadd("key", [[1, "val"], [2]]) }.should raise_error(Redis::CommandError, "ERR syntax error")
    end

    it "should allow floats as scores when adding or updating" do
      @client.zadd("key", 4.321, "val").should be(true)
      @client.zscore("key", "val").should == 4.321

      @client.zadd("key", 54.3210, "val").should be(false)
      @client.zscore("key", "val").should == 54.321
    end

    it "should remove members from sorted sets" do
      @client.zrem("key", "val").should be(false)
      @client.zadd("key", 1, "val").should be(true)
      @client.zrem("key", "val").should be(true)
    end

    it "should remove sorted set's key when it is empty" do
      @client.zadd("key", 1, "val")
      @client.zrem("key", "val")
      @client.exists("key").should == false
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
      @client.zincrby("key", 2, "val1").should == 3
      @client.zscore("key", "val1").should == 3
    end

    it "initializes the sorted set if the key wasnt already set" do
      @client.zincrby("key", 1, "val1").should == 1
    end

    it "should convert the key to a string for zscore" do
      @client.zadd("key", 1, 1)
      @client.zscore("key", 1).should == 1
    end
    #it "should intersect multiple sorted sets and store the resulting sorted set in a new key"

    it "should return a range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrange("key", 0, -1).should == ["one", "two", "three"]
      @client.zrange("key", 1, 2).should == ["two", "three"]
      @client.zrange("key", 0, -1, :withscores => true).should == [["one", 1], ["two", 2], ["three", 3]]
      @client.zrange("key", 1, 2, :with_scores => true).should == [["two", 2], ["three", 3]]
    end

    it "should return a reversed range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrange("key", 0, -1).should == ["three", "two", "one"]
      @client.zrevrange("key", 1, 2).should == ["two", "one"]
      @client.zrevrange("key", 0, -1, :withscores => true).should == [["three", 3], ["two", 2], ["one", 1]]
      @client.zrevrange("key", 0, -1, :with_scores => true).should == [["three", 3], ["two", 2], ["one", 1]]
    end

    it "should return a range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrangebyscore("key", 0, 100).should == ["one", "two", "three"]
      @client.zrangebyscore("key", 1, 2).should == ["one", "two"]
      @client.zrangebyscore("key", 0, 100, :withscores => true).should == [["one", 1], ["two", 2], ["three", 3]]
      @client.zrangebyscore("key", 1, 2, :with_scores => true).should == [["one", 1], ["two", 2]]
      @client.zrangebyscore("key", 0, 100, :limit => [0, 1]).should == ["one"]
      @client.zrangebyscore("key", 0, 100, :limit => [0, -1]).should == ["one", "two", "three"]
      @client.zrangebyscore("key", 0, 100, :limit => [1, -1], :with_scores => true).should == [["two", 2], ["three", 3]]
      @client.zrangebyscore("key", '-inf', '+inf').should == ["one", "two", "three"]
      @client.zrangebyscore("key", 2, '+inf').should == ["two", "three"]
      @client.zrangebyscore("key", '-inf', 2).should == ['one', "two"]
    end

    it "should return a reversed range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrangebyscore("key", 100, 0).should == ["three", "two", "one"]
      @client.zrevrangebyscore("key", 2, 1).should == ["two", "one"]
      @client.zrevrangebyscore("key", 1, 2).should == []
      @client.zrevrangebyscore("key", 2, 1, :with_scores => true).should == [["two", 2], ["one", 1]]
      @client.zrevrangebyscore("key", 100, 0, :limit => [0, 1]).should == ["three"]
      @client.zrevrangebyscore("key", 100, 0, :limit => [0, -1]).should == ["three", "two", "one"]
      @client.zrevrangebyscore("key", 100, 0, :limit => [1, -1], :with_scores => true).should == [["two", 2], ["one", 1]]
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

    it "should create intersections between multiple (sorted) sets and store the resulting sorted set in a new key" do
      @client.zadd("key1", 1, "one")
      @client.zadd("key1", 2, "two")
      @client.zadd("key1", 3, "three")
      @client.zadd("key2", 5, "two")
      @client.zadd("key2", 7, "three")
      @client.sadd("key3", 'one')
      @client.sadd("key3", 'two')

      @client.zinterstore("out", ["key1", "key2"]).should == 2
      @client.zrange("out", 0, 100, :with_scores => true).should == [['two', 7], ['three', 10]]

      @client.zinterstore("out", ["key1", "key3"]).should == 2
      @client.zrange("out", 0, 100, :with_scores => true).should == [['one', 2], ['two', 3]]

      @client.zinterstore("out", ["key1", "key2", "key3"]).should == 1
      @client.zrange("out", 0, 100, :with_scores => true).should == [['two', 8]]

      @client.zinterstore("out", ["key1", "no_key"]).should == 0
      @client.zrange("out", 0, 100, :with_scores => true).should == []
    end

    context "zremrangebyscore" do
      it "should remove items by score" do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        @client.zremrangebyscore("key", 0, 2).should == 2
        @client.zcard("key").should == 1
      end

      it "should return 0 if the key didn't exist" do
        @client.zremrangebyscore("key", 0, 2).should == 0
      end
    end

    context '#zremrangebyrank' do
      it 'removes all elements with in the given range' do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        @client.zremrangebyrank("key", 0, 1).should == 2
        @client.zcard('key').should == 1
      end
    end

    #it "should remove all members in a sorted set within the given indexes"

    #it "should return a range of members in a sorted set, by index, with scores ordered from high to low"

    #it "should return a range of members in a sorted set, by score, with scores ordered from high to low"

    #it "should determine the index of a member in a sorted set, with scores ordered from high to low"

    #it "should get the score associated with the given member in a sorted set"

    #it "should add multiple sorted sets and store the resulting sorted set in a new key"
  end
end
