require 'spec_helper'

module FakeRedis
  describe "HashesMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should delete a hash field" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")
      @client.hdel("key1", "k1").should be(1)

      @client.hget("key1", "k1").should be_nil
      @client.hget("key1", "k2").should be == "val2"
    end

    it "should remove a hash with no keys left" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")
      @client.hdel("key1", "k1").should be(1)
      @client.hdel("key1", "k2").should be(1)

      @client.exists("key1").should be == false
    end

    it "should convert key to a string for hset" do
      m = double("key")
      m.stub(:to_s).and_return("foo")

      @client.hset("key1", m, "bar")
      @client.hget("key1", "foo").should be == "bar"
    end

    it "should convert key to a string for hget" do
      m = double("key")
      m.stub(:to_s).and_return("foo")

      @client.hset("key1", "foo", "bar")
      @client.hget("key1", m).should be == "bar"
    end

    it "should determine if a hash field exists" do
      @client.hset("key1", "index", "value")

      @client.hexists("key1", "index").should be true
      @client.hexists("key2", "i2").should be false
    end

    it "should get the value of a hash field" do
      @client.hset("key1", "index", "value")

      @client.hget("key1", "index").should be == "value"
    end

    it "should get all the fields and values in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hgetall("key1").should be == {"i1" => "val1", "i2" => "val2"}
    end

    it "should increment the integer value of a hash field by the given number" do
      @client.hset("key1", "cont1", "5")
      @client.hincrby("key1", "cont1", "5").should be == 10
      @client.hget("key1", "cont1").should be == "10"
    end

    it "should increment non existing hash keys" do
      @client.hget("key1", "cont2").should be_nil
      @client.hincrby("key1", "cont2", "5").should be == 5
    end

    it "should increment the float value of a hash field by the given float" do
      @client.hset("key1", "cont1", 5.0)
      @client.hincrbyfloat("key1", "cont1", 4.1).should be == 9.1
      @client.hget("key1", "cont1").should be == "9.1"
    end

    it "should increment non existing hash keys" do
      @client.hget("key1", "cont2").should be_nil
      @client.hincrbyfloat("key1", "cont2", 5.5).should be == 5.5
    end

    it "should get all the fields in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hkeys("key1").should =~ ["i1", "i2"]
      @client.hkeys("key2").should be == []
    end

    it "should get the number of fields in a hash" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hlen("key1").should be == 2
    end

    it "should get the values of all the given hash fields" do
      @client.hset("key1", "i1", "val1")
      @client.hset("key1", "i2", "val2")

      @client.hmget("key1", "i1", "i2", "i3").should =~ ["val1", "val2", nil]
      @client.hmget("key1", ["i1", "i2", "i3"]).should =~ ["val1", "val2", nil]

      @client.hmget("key2", "i1", "i2").should be == [nil, nil]
    end

    it "should throw an argument error when you don't ask for any keys" do
      lambda { @client.hmget("key1") }.should raise_error(Redis::CommandError)
    end

    it "should reject an empty list of values" do
      lambda { @client.hmset("key") }.should raise_error(Redis::CommandError)
      @client.exists("key").should be false
    end

    it "rejects an insert with a key but no value" do
      lambda { @client.hmset("key", 'foo') }.should raise_error(Redis::CommandError)
      lambda { @client.hmset("key", 'foo', 3, 'bar') }.should raise_error(Redis::CommandError)
      @client.exists("key").should be false
    end

    it "should reject the wrong number of arguments" do
      lambda { @client.hmset("hash", "foo1", "bar1", "foo2", "bar2", "foo3") }.should raise_error(Redis::CommandError, "ERR wrong number of arguments for HMSET")
    end

    it "should set multiple hash fields to multiple values" do
      @client.hmset("key", "k1", "value1", "k2", "value2")

      @client.hget("key", "k1").should be == "value1"
      @client.hget("key", "k2").should be == "value2"
    end

    it "should set multiple hash fields from a ruby hash to multiple values" do
      @client.mapped_hmset("foo", :k1 => "value1", :k2 => "value2")

      @client.hget("foo", "k1").should be == "value1"
      @client.hget("foo", "k2").should be == "value2"
    end

    it "should set the string value of a hash field" do
      @client.hset("key1", "k1", "val1").should be == true
      @client.hset("key1", "k1", "val1").should be == false

      @client.hget("key1", "k1").should be == "val1"
    end

    it "should set the value of a hash field, only if the field does not exist" do
      @client.hset("key1", "k1", "val1")
      @client.hsetnx("key1", "k1", "value").should be == false
      @client.hsetnx("key1", "k2", "val2").should be == true
      @client.hsetnx("key1", :k1, "value").should be == false
      @client.hsetnx("key1", :k3, "val3").should be == true

      @client.hget("key1", "k1").should be == "val1"
      @client.hget("key1", "k2").should be == "val2"
      @client.hget("key1", "k3").should be == "val3"
    end

    it "should get all the values in a hash" do
      @client.hset("key1", "k1", "val1")
      @client.hset("key1", "k2", "val2")

      @client.hvals("key1").should =~ ["val1", "val2"]
    end

    it "should accept a list of array pairs as arguments and not throw an invalid argument number error" do
      @client.hmset("key1", [:k1, "val1"], [:k2, "val2"], [:k3, "val3"])
      @client.hget("key1", :k1).should be == "val1"
      @client.hget("key1", :k2).should be == "val2"
      @client.hget("key1", :k3).should be == "val3"
    end

    it "should reject a list of arrays that contain an invalid number of arguments" do
      expect { @client.hmset("key1", [:k1, "val1"], [:k2, "val2", "bogus val"]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for HMSET")
    end

    it "should convert a integer field name to string for hdel" do
      @client.hset("key1", "1", 1)
      @client.hdel("key1", 1).should be(1)
    end

    it "should convert a integer field name to string for hexists" do
      @client.hset("key1", "1", 1)
      @client.hexists("key1", 1).should be true
    end

    it "should convert a integer field name to string for hincrby" do
      @client.hset("key1", 1, 0)
      @client.hincrby("key1", 1, 1).should be(1)
    end
  end
end
