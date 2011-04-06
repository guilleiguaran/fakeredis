#require 'spec_helper'

#module FakeRedis
  #describe "SortedSetsMethods" do
    #before(:each) do
      #@client = FakeRedis::Redis.new
    #end

    #it "should add a member to a sorted set, or update its score if it already exists" do
      #@client.zadd("key", 1, "val")

      #@client.zcard("key").should == 1
    #end

    #it "should get the number of members in a sorted set" do
      #@client.zadd("key", 1, "val2")
      #@client.zadd("key", 2, "val1")
      #@client.zadd("key", 5, "val3")

      #@client.zcard("key").should == 3
    #end

    #it "should count the members in a sorted set with scores within the given values" do
      #@client.zadd("key", 1, "val1")
      #@client.zadd("key", 2, "val2")
      #@client.zadd("key", 3, "val3")

      #@client.zcount("key", 2, 3).should == 2
    #end

    #it "should increment the score of a member in a sorted set" do
      #@client.zadd("key", 1, "val1")
      #@client.zincrby("key", 2, "val1")

      #@client.zscore("key", "val1").should == 3
    #end

    #it "should intersect multiple sorted sets and store the resulting sorted set in a new key"

    #it "should return a range of members in a sorted set, by index" do
      #@client.zadd("key", 1, "one")
      #@client.zadd("key", 2, "two")
      #@client.zadd("key", 3, "three")

      #@client.zrange("key", 0, -1).should == ["one", "two", "three"]

    #end

    #it "should return a range of members in a sorted set, by score" do
      #@client.zadd("key", 1, "one")
      #@client.zadd("key", 2, "two")
      #@client.zadd("key", 3, "three")

      #@client.zrangescore("key", 0, -1).should == ["three", "two", "one"]
    #end

    #it "should determine the index of a member in a sorted set" do
      #@client.zadd("key", 1, "one")
      #@client.zadd("key", 2, "two")
      #@client.zadd("key", 3, "three")

      #@client.zrank("key", "three").should == 2
    #end

    #it "should remove a member from a sorted set"

    #it "should remove all members in a sorted set within the given indexes"

    #it "should remove all members in a sorted set within the given scores"

    #it "should return a range of members in a sorted set, by index, with scores ordered from high to low"

    #it "should return a range of members in a sorted set, by score, with scores ordered from high to low"

    #it "should determine the index of a member in a sorted set, with scores ordered from high to low"

    #it "should get the score associated with the given member in a sorted set"

    #it "should add multiple sorted sets and store the resulting sorted set in a new key"
  #end
#end
