require 'spec_helper'

module FakeRedis
  describe "ServerMethods" do

    before(:each) do
      @client = Redis.new
    end

    it "should return the number of keys in the selected database" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key2", "two")

      @client.dbsize.should == 2
    end

    it "should get information and statistics about the server" do
      @client.info.key?("redis_version").should == true
    end

    describe "multiple databases" do
      it "should default to database 0" do
        @client.inspect.should =~ %r#/0>$#
      end

      it "should select another database" do
        @client.select(1)
        @client.inspect.should =~ %r#/1>$#
      end

      it "should store keys separately in each database" do
        @client.select(0).should == "OK"
        @client.set("key1", "1")
        @client.set("key2", "2")

        @client.select(1)
        @client.set("key3", "3")
        @client.set("key4", "4")
        @client.set("key5", "5")

        @client.select(0)
        @client.dbsize.should == 2
        @client.exists("key1").should be_true
        @client.exists("key3").should be_false

        @client.select(1)
        @client.dbsize.should == 3
        @client.exists("key4").should be_true
        @client.exists("key2").should be_false

        @client.flushall
        @client.dbsize.should == 0

        @client.select(0)
        @client.dbsize.should == 0
      end

      it "should flush a database" do
        @client.select(0)
        @client.set("key1", "1")
        @client.set("key2", "2")
        @client.dbsize.should == 2

        @client.select(1)
        @client.set("key3", "3")
        @client.set("key4", "4")
        @client.dbsize.should == 2

        @client.flushdb.should == "OK"

        @client.dbsize.should == 0
        @client.select(0)
        @client.dbsize.should == 2
      end

      it "should flush all databases" do
        @client.select(0)
        @client.set("key3", "3")
        @client.set("key4", "4")
        @client.dbsize.should == 2

        @client.select(1)
        @client.set("key3", "3")
        @client.set("key4", "4")
        @client.dbsize.should == 2

        @client.flushall.should == "OK"

        @client.dbsize.should == 0
        @client.select(0)
        @client.dbsize.should == 0
      end
    end
  end
end
