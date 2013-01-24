require 'spec_helper'

module FakeRedis
  describe "ListsMethods" do
    before(:each) do
      @client = Redis.new
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

    it 'should not allow multiple values to be added to a list in a single rpush' do
      # redis-rb v2.2.2 calls #to_s on the second argument
      @client.rpush('key1', [1, 2, 3])
      @client.lrange('key1', 0, -1).should == [%{[1, 2, 3]}]
    end

    it 'should allow multiple values to be added to a list in a single lpush' do
      # redis-rb v2.2.2 calls #to_s on the second argument
      @client.lpush('key1', [1, 2, 3])
      @client.lrange('key1', 0, -1).should == [%{[1, 2, 3]}]
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
      @client.llen("key1").should == 2
    end

    it "should remove list's key when list is empty" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.lrem("key1", 1, "v1")
      @client.lrem("key1", 1, "v2")

      @client.exists("key1").should == false
    end

    it "should set the value of an element in a list by its index" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.lset("key1", 0, "four")
      @client.lset("key1", -2, "five")
      @client.lrange("key1", 0, -1).should == ["four", "five", "three"]

      lambda { @client.lset("key1", 4, "six") }.should raise_error(RuntimeError, "ERR index out of range")
    end

    it "should trim a list to the specified range" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.ltrim("key1", 1, -1)
      @client.lrange("key1", 0, -1).should == ["two", "three"]
    end

    it "should remove and get the last element in a list" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.rpop("key1").should == "three"
      @client.lrange("key1", 0, -1).should == ["one", "two"]
    end

    it "should remove the last element in a list, append it to another list and return it" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.rpoplpush("key1", "key2").should be == "three"

      @client.lrange("key1", 0, -1).should == ["one", "two"]
      @client.lrange("key2", 0, -1).should == ["three"]
    end

    it "should append a value to a list" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")

      @client.lrange("key1", 0, -1).should == ["one", "two"]
    end

    it "should append a value to a list, only if the list exists" do
      @client.rpush("key1", "one")
      @client.rpushx("key1", "two")
      @client.rpushx("key2", "two")

      @client.lrange("key1", 0, -1).should == ["one", "two"]
      @client.lrange("key2", 0, -1).should == []
    end
  end
end
