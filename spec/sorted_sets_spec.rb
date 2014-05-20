require 'spec_helper'

module FakeRedis
  Infinity = 1.0/0.0

  describe "SortedSetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a sorted set, or update its score if it already exists" do
      @client.zadd("key", 1, "val").should be(true)
      @client.zscore("key", "val").should be == 1.0

      @client.zadd("key", 2, "val").should be(false)
      @client.zscore("key", "val").should be == 2.0

      # These assertions only work in redis-rb v3.0.2 or higher
      @client.zadd("key2", "inf", "val").should be == true
      @client.zscore("key2", "val").should be == Infinity

      @client.zadd("key3", "+inf", "val").should be == true
      @client.zscore("key3", "val").should be == Infinity

      @client.zadd("key4", "-inf", "val").should be == true
      @client.zscore("key4", "val").should be == -Infinity
    end

    it "should return a nil score for value not in a sorted set or empty key" do
      @client.zadd "key", 1, "val"

      @client.zscore("key", "val").should be == 1.0
      @client.zscore("key", "val2").should be_nil
      @client.zscore("key2", "val").should be_nil
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

      @client.zadd("key", [[5, "val5"], [3, "val6"]]).should be == 2
      @client.zscore("key", "val5").should be == 5
      @client.zscore("key", "val6").should be == 3
    end

    it "should error with wrong number of arguments when adding members" do
      lambda { @client.zadd("key") }.should raise_error(ArgumentError, "wrong number of arguments")
      lambda { @client.zadd("key", 1) }.should raise_error(ArgumentError, "wrong number of arguments")
      lambda { @client.zadd("key", [1]) }.should raise_error(Redis::CommandError, "ERR wrong number of arguments for 'zadd' command")
      lambda { @client.zadd("key", [1, "val", 2]) }.should raise_error(Redis::CommandError, "ERR syntax error")
      lambda { @client.zadd("key", [[1, "val"], [2]]) }.should raise_error(Redis::CommandError, "ERR syntax error")
    end

    it "should allow floats as scores when adding or updating" do
      @client.zadd("key", 4.321, "val").should be(true)
      @client.zscore("key", "val").should be == 4.321

      @client.zadd("key", 54.3210, "val").should be(false)
      @client.zscore("key", "val").should be == 54.321
    end

    it "should remove members from sorted sets" do
      @client.zrem("key", "val").should be(false)
      @client.zadd("key", 1, "val").should be(true)
      @client.zrem("key", "val").should be(true)
    end

    it "should remove multiple members from sorted sets" do
      @client.zrem("key2", %w(val)).should be == 0
      @client.zrem("key2", %w(val val2 val3)).should be == 0

      @client.zadd("key2", 1, "val")
      @client.zadd("key2", 1, "val2")
      @client.zadd("key2", 1, "val3")

      @client.zrem("key2", %w(val val2 val3 val4)).should be == 3
    end

    it "should remove sorted set's key when it is empty" do
      @client.zadd("key", 1, "val")
      @client.zrem("key", "val")
      @client.exists("key").should be == false
    end

    it "should get the number of members in a sorted set" do
      @client.zadd("key", 1, "val2")
      @client.zadd("key", 2, "val1")
      @client.zadd("key", 5, "val3")

      @client.zcard("key").should be == 3
    end

    it "should count the members in a sorted set with scores within the given values" do
      @client.zadd("key", 1, "val1")
      @client.zadd("key", 2, "val2")
      @client.zadd("key", 3, "val3")

      @client.zcount("key", 2, 3).should be == 2
    end

    it "should increment the score of a member in a sorted set" do
      @client.zadd("key", 1, "val1")
      @client.zincrby("key", 2, "val1").should be == 3
      @client.zscore("key", "val1").should be == 3
    end

    it "initializes the sorted set if the key wasnt already set" do
      @client.zincrby("key", 1, "val1").should be == 1
    end

    it "should convert the key to a string for zscore" do
      @client.zadd("key", 1, 1)
      @client.zscore("key", 1).should be == 1
    end

    # These won't pass until redis-rb releases v3.0.2
    it "should handle infinity values when incrementing a sorted set key" do
      @client.zincrby("bar", "+inf", "s2").should be == Infinity
      @client.zincrby("bar", "-inf", "s1").should be == -Infinity
    end

    it "should return a range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrange("key", 0, -1).should be == ["one", "two", "three"]
      @client.zrange("key", 1, 2).should be == ["two", "three"]
      @client.zrange("key", 0, -1, :withscores => true).should be == [["one", 1], ["two", 2], ["three", 3]]
      @client.zrange("key", 1, 2, :with_scores => true).should be == [["two", 2], ["three", 3]]
    end

    it "should sort zrange results logically" do
      @client.zadd("key", 5, "val2")
      @client.zadd("key", 5, "val3")
      @client.zadd("key", 5, "val1")

      @client.zrange("key", 0, -1).should be == %w(val1 val2 val3)
      @client.zrange("key", 0, -1, :with_scores => true).should be == [["val1", 5], ["val2", 5], ["val3", 5]]
    end

    it "should return a reversed range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrange("key", 0, -1).should be == ["three", "two", "one"]
      @client.zrevrange("key", 1, 2).should be == ["two", "one"]
      @client.zrevrange("key", 0, -1, :withscores => true).should be == [["three", 3], ["two", 2], ["one", 1]]
      @client.zrevrange("key", 0, -1, :with_scores => true).should be == [["three", 3], ["two", 2], ["one", 1]]
    end

    it "should return a range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrangebyscore("key", 0, 100).should be == ["one", "two", "three"]
      @client.zrangebyscore("key", 1, 2).should be == ["one", "two"]
      @client.zrangebyscore("key", 1, '(2').should be == ['one']
      @client.zrangebyscore("key", '(1', 2).should be == ['two']
      @client.zrangebyscore("key", '(1', '(2').should be == []
      @client.zrangebyscore("key", 0, 100, :withscores => true).should be == [["one", 1], ["two", 2], ["three", 3]]
      @client.zrangebyscore("key", 1, 2, :with_scores => true).should be == [["one", 1], ["two", 2]]
      @client.zrangebyscore("key", 0, 100, :limit => [0, 1]).should be == ["one"]
      @client.zrangebyscore("key", 0, 100, :limit => [0, -1]).should be == ["one", "two", "three"]
      @client.zrangebyscore("key", 0, 100, :limit => [1, -1], :with_scores => true).should be == [["two", 2], ["three", 3]]
      @client.zrangebyscore("key", '-inf', '+inf').should be == ["one", "two", "three"]
      @client.zrangebyscore("key", 2, '+inf').should be == ["two", "three"]
      @client.zrangebyscore("key", '-inf', 2).should be == ['one', "two"]

      @client.zrangebyscore("badkey", 1, 2).should be == []
    end

    it "should return a reversed range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrangebyscore("key", 100, 0).should be == ["three", "two", "one"]
      @client.zrevrangebyscore("key", 2, 1).should be == ["two", "one"]
      @client.zrevrangebyscore("key", 1, 2).should be == []
      @client.zrevrangebyscore("key", 2, 1, :with_scores => true).should be == [["two", 2.0], ["one", 1.0]]
      @client.zrevrangebyscore("key", 100, 0, :limit => [0, 1]).should be == ["three"]
      @client.zrevrangebyscore("key", 100, 0, :limit => [0, -1]).should be == ["three", "two", "one"]
      @client.zrevrangebyscore("key", 100, 0, :limit => [1, -1], :with_scores => true).should be == [["two", 2.0], ["one", 1.0]]
    end

    it "should determine the index of a member in a sorted set" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrank("key", "three").should be == 2
      @client.zrank("key", "four").should be_nil
    end

    it "should determine the reversed index of a member in a sorted set" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      @client.zrevrank("key", "three").should be == 0
      @client.zrevrank("key", "four").should be_nil
    end

    it "should not raise errors for zrank() on accessing a non-existing key in a sorted set" do
      @client.zrank("no_such_key", "no_suck_id").should be_nil
    end

    it "should not raise errors for zrevrank() on accessing a non-existing key in a sorted set" do
      @client.zrevrank("no_such_key", "no_suck_id").should be_nil
    end

    describe "#zinterstore" do
      before do
        @client.zadd("key1", 1, "one")
        @client.zadd("key1", 2, "two")
        @client.zadd("key1", 3, "three")
        @client.zadd("key2", 5, "two")
        @client.zadd("key2", 7, "three")
        @client.sadd("key3", 'one')
        @client.sadd("key3", 'two')
      end

      it "should intersect two keys with custom scores" do
        @client.zinterstore("out", ["key1", "key2"]).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [['two', (2 + 5)], ['three', (3 + 7)]]
      end

      it "should intersect two keys with a default score" do
        @client.zinterstore("out", ["key1", "key3"]).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [['one', (1 + 1)], ['two', (2 + 1)]]
      end

      it "should intersect more than two keys" do
        @client.zinterstore("out", ["key1", "key2", "key3"]).should be == 1
        @client.zrange("out", 0, -1, :with_scores => true).should be == [['two', (2 + 5 + 1)]]
      end

      it "should not intersect an unknown key" do
        @client.zinterstore("out", ["key1", "no_key"]).should be == 0
        @client.zrange("out", 0, -1, :with_scores => true).should be == []
      end

      it "should intersect two keys by minimum values" do
        @client.zinterstore("out", ["key1", "key2"], :aggregate => :min).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["two", 2], ["three", 3]]
      end

      it "should intersect two keys by maximum values" do
        @client.zinterstore("out", ["key1", "key2"], :aggregate => :max).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["two", 5], ["three", 7]]
      end

      it "should intersect two keys by explicitly summing values" do
        @client.zinterstore("out", %w(key1 key2), :aggregate => :sum).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["two", (2 + 5)], ["three", (3 + 7)]]
      end

      it "should intersect two keys with weighted values" do
        @client.zinterstore("out", %w(key1 key2), :weights => [10, 1]).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["two", (2 * 10 + 5)], ["three", (3 * 10 + 7)]]
      end

      it "should intersect two keys with weighted minimum values" do
        @client.zinterstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :min).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["two", 5], ["three", 7]]
      end

      it "should intersect two keys with weighted maximum values" do
        @client.zinterstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :max).should be == 2
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["two", (2 * 10)], ["three", (3 * 10)]]
      end

      it "should error without enough weights given" do
        lambda { @client.zinterstore("out", %w(key1 key2), :weights => []) }.should raise_error(Redis::CommandError, "ERR syntax error")
        lambda { @client.zinterstore("out", %w(key1 key2), :weights => [10]) }.should raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with too many weights given" do
        lambda { @client.zinterstore("out", %w(key1 key2), :weights => [10, 1, 1]) }.should raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with an invalid aggregate" do
        lambda { @client.zinterstore("out", %w(key1 key2), :aggregate => :invalid) }.should raise_error(Redis::CommandError, "ERR syntax error")
      end
    end

    context "zremrangebyscore" do
      it "should remove items by score" do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        @client.zremrangebyscore("key", 0, 2).should be == 2
        @client.zcard("key").should be == 1
      end

      it "should remove items by score with infinity" do # Issue #50
        @client.zadd("key", 10.0, "one")
        @client.zadd("key", 20.0, "two")
        @client.zadd("key", 30.0, "three")
        @client.zremrangebyscore("key", "-inf", "+inf").should be == 3
        @client.zcard("key").should be == 0
        @client.zscore("key", "one").should be_nil
        @client.zscore("key", "two").should be_nil
        @client.zscore("key", "three").should be_nil
      end

      it "should return 0 if the key didn't exist" do
        @client.zremrangebyscore("key", 0, 2).should be == 0
      end
    end

    context '#zremrangebyrank' do
      it 'removes all elements with in the given range' do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        @client.zremrangebyrank("key", 0, 1).should be == 2
        @client.zcard('key').should be == 1
      end

      it 'handles out of range requests' do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        @client.zremrangebyrank("key", 25, -1).should be == 0
        @client.zcard('key').should be == 3
      end

      it "should return 0 if the key didn't exist" do
        @client.zremrangebyrank("key", 0, 1).should be == 0
      end
    end

    describe "#zunionstore" do
      before do
        @client.zadd("key1", 1, "val1")
        @client.zadd("key1", 2, "val2")
        @client.zadd("key1", 3, "val3")
        @client.zadd("key2", 5, "val2")
        @client.zadd("key2", 7, "val3")
        @client.sadd("key3", "val1")
        @client.sadd("key3", "val2")
      end

      it "should union two keys with custom scores" do
        @client.zunionstore("out", %w(key1 key2)).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", 1], ["val2", (2 + 5)], ["val3", (3 + 7)]]
      end

      it "should union two keys with a default score" do
        @client.zunionstore("out", %w(key1 key3)).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", (1 + 1)], ["val2", (2 + 1)], ["val3", 3]]
      end

      it "should union more than two keys" do
        @client.zunionstore("out", %w(key1 key2 key3)).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", (1 + 1)], ["val2", (2 + 5 + 1)], ["val3", (3 + 7)]]
      end

      it "should union with an unknown key" do
        @client.zunionstore("out", %w(key1 no_key)).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", 1], ["val2", 2], ["val3", 3]]
      end

      it "should union two keys by minimum values" do
        @client.zunionstore("out", %w(key1 key2), :aggregate => :min).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", 1], ["val2", 2], ["val3", 3]]
      end

      it "should union two keys by maximum values" do
        @client.zunionstore("out", %w(key1 key2), :aggregate => :max).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", 1], ["val2", 5], ["val3", 7]]
      end

      it "should union two keys by explicitly summing values" do
        @client.zunionstore("out", %w(key1 key2), :aggregate => :sum).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", 1], ["val2", (2 + 5)], ["val3", (3 + 7)]]
      end

      it "should union two keys with weighted values" do
        @client.zunionstore("out", %w(key1 key2), :weights => [10, 1]).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", (1 * 10)], ["val2", (2 * 10 + 5)], ["val3", (3 * 10 + 7)]]
      end

      it "should union two keys with weighted minimum values" do
        @client.zunionstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :min).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val2", 5], ["val3", 7], ["val1", (1 * 10)]]
      end

      it "should union two keys with weighted maximum values" do
        @client.zunionstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :max).should be == 3
        @client.zrange("out", 0, -1, :with_scores => true).should be == [["val1", (1 * 10)], ["val2", (2 * 10)], ["val3", (3 * 10)]]
      end

      it "should error without enough weights given" do
        lambda { @client.zunionstore("out", %w(key1 key2), :weights => []) }.should raise_error(Redis::CommandError, "ERR syntax error")
        lambda { @client.zunionstore("out", %w(key1 key2), :weights => [10]) }.should raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with too many weights given" do
        lambda { @client.zunionstore("out", %w(key1 key2), :weights => [10, 1, 1]) }.should raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with an invalid aggregate" do
        lambda { @client.zunionstore("out", %w(key1 key2), :aggregate => :invalid) }.should raise_error(Redis::CommandError, "ERR syntax error")
      end
    end

    #it "should remove all members in a sorted set within the given indexes"

    #it "should return a range of members in a sorted set, by index, with scores ordered from high to low"

    #it "should return a range of members in a sorted set, by score, with scores ordered from high to low"

    #it "should determine the index of a member in a sorted set, with scores ordered from high to low"

    #it "should get the score associated with the given member in a sorted set"

    #it "should add multiple sorted sets and store the resulting sorted set in a new key"

    it "zrem should remove members add by zadd" do
      @client.zadd("key1", 1, 3)
      @client.zrem("key1", 3)
      @client.zscore("key1", 3).should be_nil
    end
  end
end
