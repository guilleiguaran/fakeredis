require 'spec_helper'

module FakeRedis
  describe "ListsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should get an element from a list by its index" do
      @client.lpush("key1", "val1")
      @client.lpush("key1", "val2")

      @client.lindex("key1", 0).should be == "val2"
      @client.lindex("key1", -1).should be == "val1"
      @client.lindex("key1", 3).should be == nil
    end

    it "should insert an element before or after another element in a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v3")
      @client.linsert("key1", :before, "v3", "v2")

      @client.lrange("key1", 0, -1).should be == ["v1", "v2", "v3"]
    end

    it 'should allow multiple values to be added to a list in a single rpush' do
      @client.rpush('key1', [1, 2, 3])
      @client.lrange('key1', 0, -1).should be == ['1', '2', '3']
    end

    it 'should allow multiple values to be added to a list in a single lpush' do
      @client.lpush('key1', [1, 2, 3])
      @client.lrange('key1', 0, -1).should be == ['3', '2', '1']
    end

    it "should error if an invalid where argument is given" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v3")
      lambda { @client.linsert("key1", :invalid, "v3", "v2") }.should raise_error(Redis::CommandError, "ERR syntax error")
    end

    it "should get the length of a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")

      @client.llen("key1").should be == 2
      @client.llen("key2").should be == 0
    end

    it "should remove and get the first element in a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v3")

      @client.lpop("key1").should be == "v1"
      @client.lrange("key1", 0, -1).should be == ["v2", "v3"]
    end

    it "should prepend a value to a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")

      @client.lrange("key1", 0, -1).should be == ["v1", "v2"]
    end

    it "should prepend a value to a list, only if the list exists" do
      @client.lpush("key1", "v1")

      @client.lpushx("key1", "v2")
      @client.lpushx("key2", "v3")

      @client.lrange("key1", 0, -1).should be == ["v2", "v1"]
      @client.llen("key2").should be == 0
    end

    it "should get a range of elements from a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v3")

      @client.lrange("key1", 1, -1).should be == ["v2", "v3"]
    end

    it "should remove elements from a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v1")

      @client.lrem("key1", 1, "v1").should be == 1
      @client.lrem("key1", -2, "v2").should be == 2
      @client.llen("key1").should be == 2
    end

    it "should remove list's key when list is empty" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.lrem("key1", 1, "v1")
      @client.lrem("key1", 1, "v2")

      @client.exists("key1").should be == false
    end

    it "should set the value of an element in a list by its index" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.lset("key1", 0, "four")
      @client.lset("key1", -2, "five")
      @client.lrange("key1", 0, -1).should be == ["four", "five", "three"]

      lambda { @client.lset("key1", 4, "six") }.should raise_error(Redis::CommandError, "ERR index out of range")
    end

    it "should trim a list to the specified range" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.ltrim("key1", 1, -1).should be == "OK"
      @client.lrange("key1", 0, -1).should be == ["two", "three"]
    end


    context "when the list is smaller than the requested trim" do
      before { @client.rpush("listOfOne", "one") }

      context "trimming with a negative start (specifying a max)" do
        before { @client.ltrim("listOfOne", -5, -1) }

        it "returns the unmodified list" do
          @client.lrange("listOfOne", 0, -1).should be == ["one"]
        end
      end
    end

    context "when the list is larger than the requested trim" do
      before do
        @client.rpush("maxTest", "one")
        @client.rpush("maxTest", "two")
        @client.rpush("maxTest", "three")
        @client.rpush("maxTest", "four")
        @client.rpush("maxTest", "five")
        @client.rpush("maxTest", "six")
      end

      context "trimming with a negative start (specifying a max)" do
        before { @client.ltrim("maxTest", -5, -1) }

        it "should trim a list to the specified maximum size" do
          @client.lrange("maxTest", 0, -1).should be == ["two","three", "four", "five", "six"]
        end
      end
    end


    it "should remove and return the last element in a list" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.rpop("key1").should be == "three"
      @client.lrange("key1", 0, -1).should be == ["one", "two"]
    end

    it "should remove the last element in a list, append it to another list and return it" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.rpoplpush("key1", "key2").should be == "three"

      @client.lrange("key1", 0, -1).should be == ["one", "two"]
      @client.lrange("key2", 0, -1).should be == ["three"]
    end

    context 'when the source list is empty' do
      it 'rpoplpush does not add anything to the destination list' do
        @client.rpoplpush("source", "destination")

        @client.lrange("destination", 0, -1).should be == []
      end
    end

    it "should append a value to a list" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")

      @client.lrange("key1", 0, -1).should be == ["one", "two"]
    end

    it "should append a value to a list, only if the list exists" do
      @client.rpush("key1", "one")
      @client.rpushx("key1", "two")
      @client.rpushx("key2", "two")

      @client.lrange("key1", 0, -1).should be == ["one", "two"]
      @client.lrange("key2", 0, -1).should be == []
    end
  end
end
