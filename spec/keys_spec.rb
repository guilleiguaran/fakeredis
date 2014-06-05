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

      @client.get("key1").should be == nil
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

    it "should return true when setting expires on keys that exist" do
      @client.set("key1", "1")
      @client.expire("key1", 1).should == true
    end

    it "should return false when attempting to set expires on a key that does not exist" do
      @client.expire("key1", 1).should == false
    end

    it "should determine if a key exists" do
      @client.set("key1", "1")

      @client.exists("key1").should be == true
      @client.exists("key2").should be == false
    end

    it "should set a key's time to live in seconds" do
      @client.set("key1", "1")
      @client.expire("key1", 1)

      @client.ttl("key1").should be == 1
    end

    it "should set the expiration for a key as a UNIX timestamp" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)

      @client.ttl("key1").should be == 2
    end

    it "should not have an expiration after re-set" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)
      @client.set("key1", "1")

      @client.ttl("key1").should be == -1
    end

    it "should not have a ttl if expired (and thus key does not exist)" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      @client.ttl("key1").should be == -2
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

      @client.mget("key1", "key2").should be == [nil, "2"]
    end

    it "should only find keys that aren't expired" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.expireat("key1", Time.now.to_i)

      @client.keys.should be == ["key2"]
    end

    it "should not exist if expired" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      @client.exists("key1").should be false
    end

    it "should find all keys matching the given pattern" do
      @client.set("key:a", "1")
      @client.set("key:b", "2")
      @client.set("key:c", "3")
      @client.set("akeyd", "4")
      @client.set("key1", "5")

      @client.mset("database", 1, "above", 2, "suitability", 3, "able", 4)

      @client.keys("key:*").should =~ ["key:a", "key:b", "key:c"]
      @client.keys("ab*").should =~ ["above", "able"]
    end

    it "should remove the expiration from a key" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 1)
      @client.persist("key1").should be == true
      @client.persist("key1").should be == false

      @client.ttl("key1").should be == -1
    end

    it "should return a random key from the keyspace" do
      @client.set("key1", "1")
      @client.set("key2", "2")

      ["key1", "key2"].include?(@client.randomkey).should be == true
    end

    it "should rename a key" do
      @client.set("key1", "2")
      @client.rename("key1", "key2")

      @client.get("key1").should be == nil
      @client.get("key2").should be == "2"
    end

    it "should rename a key, only if new key does not exist" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key3", "3")
      @client.renamenx("key1", "key2")
      @client.renamenx("key3", "key4")

      @client.get("key1").should be == "1"
      @client.get("key2").should be == "2"
      @client.get("key3").should be == nil
      @client.get("key4").should be == "3"
    end

    it "should determine the type stored at key" do
      # Non-existing key
      @client.type("key0").should be == "none"

      # String
      @client.set("key1", "1")
      @client.type("key1").should be == "string"

      # List
      @client.lpush("key2", "1")
      @client.type("key2").should be == "list"

      # Set
      @client.sadd("key3", "1")
      @client.type("key3").should be == "set"

      # Sorted Set
      @client.zadd("key4", 1.0, "1")
      @client.type("key4").should be == "zset"

      # Hash
      @client.hset("key5", "a", "1")
      @client.type("key5").should be == "hash"
    end

    it "should convert the value into a string before storing" do
      @client.set("key1", 1)
      @client.get("key1").should be == "1"

      @client.setex("key2", 30, 1)
      @client.get("key2").should be == "1"

      @client.getset("key3", 1)
      @client.get("key3").should be == "1"
    end

    it "should return 'OK' for the setex command" do
      @client.setex("key4", 30, 1).should be == "OK"
    end

    it "should convert the key into a string before storing" do
      @client.set(123, "foo")
      @client.keys.should include("123")
      @client.get("123").should be == "foo"

      @client.setex(456, 30, "foo")
      @client.keys.should include("456")
      @client.get("456").should be == "foo"

      @client.getset(789, "foo")
      @client.keys.should include("789")
      @client.get("789").should be == "foo"
    end

    it "should only operate against keys containing string values" do
      @client.sadd("key1", "one")
      lambda { @client.get("key1") }.should raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")
      lambda { @client.getset("key1", 1) }.should raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")

      @client.hset("key2", "one", "two")
      lambda { @client.get("key2") }.should raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")
      lambda { @client.getset("key2", 1) }.should raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")
    end

    it "should move a key from one database to another successfully" do
      @client.select(0)
      @client.set("key1", "1")

      @client.move("key1", 1).should be == true

      @client.select(0)
      @client.get("key1").should be_nil

      @client.select(1)
      @client.get("key1").should be == "1"
    end

    it "should fail to move a key that does not exist in the source database" do
      @client.select(0)
      @client.get("key1").should be_nil

      @client.move("key1", 1).should be == false

      @client.select(0)
      @client.get("key1").should be_nil

      @client.select(1)
      @client.get("key1").should be_nil
    end

    it "should fail to move a key that exists in the destination database" do
      @client.select(0)
      @client.set("key1", "1")

      @client.select(1)
      @client.set("key1", "2")

      @client.select(0)
      @client.move("key1", 1).should be == false

      @client.select(0)
      @client.get("key1").should be == "1"

      @client.select(1)
      @client.get("key1").should be == "2"
    end

    it "should fail to move a key to the same database" do
      @client.select(0)
      @client.set("key1", "1")

      lambda { @client.move("key1", 0) }.should raise_error(Redis::CommandError, "ERR source and destination objects are the same")

      @client.select(0)
      @client.get("key1").should be == "1"
    end

    it "should scan all keys in the database" do
      100.times do |x|
        @client.set("key#{x}", "#{x}")
      end

      cursor = 0
      all_keys = []
      loop {
        cursor, keys = @client.scan(cursor)
        all_keys += keys
        break if cursor == "0"
      }

      all_keys.uniq.size.should == 100
      all_keys[0].should =~ /key\d+/
    end

    it "should match keys to a pattern when scanning" do
      50.times do |x|
        @client.set("key#{x}", "#{x}")
      end

      @client.set("miss_me", 1)
      @client.set("pass_me", 2)

      cursor = 0
      all_keys = []
      loop {
        cursor, keys = @client.scan(cursor, :match => "key*")
        all_keys += keys
        break if cursor == "0"
      }

      all_keys.uniq.size.should == 50
    end

    it "should specify doing more work when scanning" do
      100.times do |x|
        @client.set("key#{x}", "#{x}")
      end

      cursor, all_keys = @client.scan(cursor, :count => 100)

      cursor.should == "0"
      all_keys.uniq.size.should == 100
    end

    context "with extended options" do
      it "uses ex option to set the expire time, in seconds" do
        ttl = 7

        @client.set("key1", "1", { :ex => ttl }).should == "OK"
        @client.ttl("key1").should == ttl
      end

      it "uses px option to set the expire time, in miliseconds" do
        ttl = 7000

        @client.set("key1", "1", { :px => ttl }).should == "OK"
        @client.ttl("key1").should == (ttl / 1000)
      end

      # Note that the redis-rb implementation will always give PX last.
      # Redis seems to process each expiration option and the last one wins.
      it "prefers the finer-grained PX expiration option over EX" do
        ttl_px = 6000
        ttl_ex = 10

        @client.set("key1", "1", { :px => ttl_px, :ex => ttl_ex })
        @client.ttl("key1").should == (ttl_px / 1000)

        @client.set("key1", "1", { :ex => ttl_ex, :px => ttl_px })
        @client.ttl("key1").should == (ttl_px / 1000)
      end

      it "uses nx option to only set the key if it does not already exist" do
        @client.set("key1", "1", { :nx => true }).should == true
        @client.set("key1", "2", { :nx => true }).should == false

        @client.get("key1").should == "1"
      end

      it "uses xx option to only set the key if it already exists" do
        @client.set("key2", "1", { :xx => true }).should == false
        @client.set("key2", "2")
        @client.set("key2", "1", { :xx => true }).should == true

        @client.get("key2").should == "1"
      end

      it "does not set the key if both xx and nx option are specified" do
        @client.set("key2", "1", { :nx => true, :xx => true }).should == false
        @client.get("key2").should be_nil
      end
    end
  end
end

