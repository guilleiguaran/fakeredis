require 'spec_helper'

module FakeRedis
  describe "HashesMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should delete a hash field" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")
      @client.hdel("key1", "k1")

      @client.hget("key1", "k1").should be_nil
      @client.hget("key1", "k2").should == "val2"
    end

    it "should determine if a hash field exists" do
      @client.hset("key1", "index", "value")

      @client.hexists("key1", "index").should be_true
      @client.hexists("key2", "i2").should be_false
    end

    it "should get the value of a hash field" do
      @client.hset("key1", "index", "value")

      @client.hget("key1", "index").should == "value"
    end

    it "should get all the fields and values in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hgetall("key1").should == {"i1" => "val1", "i2" => "val2"}
    end

    it "should increment the integer value of a hash field by the given number" do
      @client.hset("key1", "cont1", "5")
      @client.hincrby("key1", "cont1", "5").should == 10
      @client.hget("key1", "cont1").should == "10"
    end

    it "should increment non existing hash keys" do
      @client.hget("key1", "cont2").should be_nil
      @client.hincrby("key1", "cont2", "5").should == 5
    end

    it "should get all the fields in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hkeys("key1").should =~ ["i1", "i2"]
      @client.hkeys("key2").should == []
    end

    it "should get the number of fields in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hlen("key1").should == 2
    end

    it "should get the values of all the given hash fields" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hmget("key1", "i1", "i2", "i3").should =~ ["val1", "val2", nil]
      @client.hmget("key2", "i1", "i2").should == [nil, nil]
    end

    it "should set multiple hash fields to multiple values" do
      @client.hmset("key", "k1", "value1", "k2", "value2")

      @client.hget("key", "k1").should == "value1"
      @client.hget("key", "k2").should == "value2"
    end

    it "should set the string value of a hash field" do
      @client.hset("key1", "k1", "val1").should == true
      @client.hset("key1", "k1", "val1").should == false

      @client.hget("key1", "k1").should == "val1"
    end

    it "should set the value of a hash field, only if the field does not exist" do
      @client.hset("key1", "k1", "val1")
      @client.hsetnx("key1", "k1", "value").should == false
      @client.hsetnx("key1", "k2", "val2").should == true

      @client.hget("key1", "k1").should == "val1"
      @client.hget("key1", "k2").should == "val2"
    end

    it "should get all the values in a hash" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")

      @client.hvals("key1").should =~ ["val1", "val2"]
    end

  end
end
