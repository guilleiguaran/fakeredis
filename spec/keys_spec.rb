require 'spec_helper'

module FakeRedis
  describe "KeysMethods" do

    before(:each) do
      @client = Redis.new
    end

    it "should delete a key" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.del("key1", "key2")

      @client.get("key1").should == nil
    end

    it "should delete multiple keys" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.del(["key1", "key2"])

      @client.get("key1").should be == nil
      @client.get("key2").should be == nil
    end

    it "should error deleting no keys" do
      lambda { @client.del }.should raise_error(Redis::CommandError, "ERR wrong number of arguments for 'del' command")
      lambda { @client.del [] }.should raise_error(Redis::CommandError, "ERR wrong number of arguments for 'del' command")
    end

    it "should determine if a key exists" do
      @client.set("key1", "1")

      @client.exists("key1").should == true
      @client.exists("key2").should == false
    end

    it "should set a key's time to live in seconds" do
      @client.set("key1", "1")
      @client.expire("key1", 1)

      @client.ttl("key1").should == 1
    end

    it "should set the expiration for a key as a UNIX timestamp" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)

      @client.ttl("key1").should == 2
    end

    it 'should not have an expiration after re-set' do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)
      @client.set("key1", "1")

      @client.ttl("key1").should == -1
    end

    it "should not have a ttl if expired" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      @client.ttl("key1").should == -1
    end
    
    it "should not find a key if expired" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      @client.get("key1").should be_nil
    end

    it "should not find multiple keys if expired" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.expireat("key1", Time.now.to_i)

      @client.mget("key1", "key2").should == [nil, "2"]
    end

    it "should only find keys that aren't expired" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.expireat("key1", Time.now.to_i)

      @client.keys.should == ["key2"]
    end

    it "should not exist if expired" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      @client.exists("key1").should be_false
    end

    it "should find all keys matching the given pattern" do
      @client.set("key:a", "1")
      @client.set("key:b", "2")
      @client.set("key:c", "3")
      @client.set("akeyd", "4")
      @client.set("key1", "5")

      @client.keys("key:").should =~ ["key:a", "key:b", "key:c"]
    end

    it "should remove the expiration from a key" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)
      @client.persist("key1").should == true
      @client.persist("key1").should == false

      @client.ttl("key1").should == -1
    end

    it "should return a random key from the keyspace" do
      @client.set("key1", "1")
      @client.set("key2", "2")

      ["key1", "key2"].include?(@client.randomkey).should == true
    end

    it "should rename a key" do
      @client.set("key1", "2")
      @client.rename("key1", "key2")

      @client.get("key1").should == nil
      @client.get("key2").should == "2"
    end

    it "should rename a key, only if new key does not exist" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key3", "3")
      @client.renamenx("key1", "key2")
      @client.renamenx("key3", "key4")

      @client.get("key1").should == "1"
      @client.get("key2").should == "2"
      @client.get("key3").should == nil
      @client.get("key4").should == "3"
    end

    it "should sort the elements in a list, set or sorted set" do
      pending "SORT Command not implemented yet"
    end

    it "should determine the type stored at key" do
      @client.set("key1", "1")

      @client.type("key1").should == "string"
      @client.type("key0").should == "none"
    end

    it "should convert the value into a string before storing" do
      @client.set("key1", 1)
      @client.get("key1").should == "1"

      @client.setex("key2", 30, 1)
      @client.get("key2").should == "1"
    end
  end
end
