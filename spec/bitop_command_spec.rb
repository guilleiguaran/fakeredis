require 'spec_helper'

module FakeRedis
  describe "#bitop" do
    before(:all) do
      @client = Redis.new
    end

    before(:each) do
      @client.discard rescue nil
    end

    it 'raises an argument error when passed unsupported operation' do
      lambda { @client.bitop("meh", "dest1", "key1") }.should raise_error(Redis::CommandError)
    end

    describe "or" do
      it_should_behave_like "a bitwise operation", "or"

      it "should apply bitwise or operation" do
        @client.setbit("key1", 0, 0)
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 1)
        @client.setbit("key1", 3, 0)

        @client.setbit("key2", 0, 1)
        @client.setbit("key2", 1, 1)
        @client.setbit("key2", 2, 0)
        @client.setbit("key2", 3, 0)

        @client.bitop("or", "dest1", "key1", "key2").should be == 1
        @client.bitcount("dest1").should be == 3
        @client.getbit("dest1", 0).should be == 1
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 2).should be == 1
        @client.getbit("dest1", 3).should be == 0
      end

      it "should apply bitwise or operation with empty values" do
        @client.setbit("key1", 1, 1)

        @client.bitop("or", "dest1", "key1", "nothing_here1", "nothing_here2").should be == 1
        @client.bitcount("dest1").should be == 1
        @client.getbit("dest1", 0).should be == 0
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 2).should be == 0
      end

      it "should apply bitwise or operation with multiple keys" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 3, 1)

        @client.setbit("key2", 5, 1)
        @client.setbit("key2", 10, 1)

        @client.setbit("key3", 13, 1)
        @client.setbit("key3", 15, 1)

        @client.bitop("or", "dest1", "key1", "key2", "key3").should be == 2
        @client.bitcount("dest1").should be == 6
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 3).should be == 1
        @client.getbit("dest1", 5).should be == 1
        @client.getbit("dest1", 10).should be == 1
        @client.getbit("dest1", 13).should be == 1
        @client.getbit("dest1", 15).should be == 1
        @client.getbit("dest1", 2).should be == 0
        @client.getbit("dest1", 12).should be == 0
      end
    end

    describe "and" do
      it_should_behave_like "a bitwise operation", "and"

      it "should apply bitwise and operation" do
        @client.setbit("key1", 0, 1)
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 0)

        @client.setbit("key2", 0, 0)
        @client.setbit("key2", 1, 1)
        @client.setbit("key2", 2, 1)

        @client.bitop("and", "dest1", "key1", "key2").should be == 1
        @client.bitcount("dest1").should be == 1
        @client.getbit("dest1", 0).should be == 0
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 2).should be == 0
      end

      it "should apply bitwise and operation with empty values" do
        @client.setbit("key1", 1, 1)

        @client.bitop("and", "dest1", "key1", "nothing_here").should be == 1
        @client.bitcount("dest1").should be == 1
        @client.getbit("dest1", 0).should be == 0
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 2).should be == 0
      end

      it "should apply bitwise and operation with multiple keys" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 1)
        @client.setbit("key1", 3, 1)
        @client.setbit("key1", 4, 1)

        @client.setbit("key2", 2, 1)
        @client.setbit("key2", 3, 1)
        @client.setbit("key2", 4, 1)
        @client.setbit("key2", 5, 1)

        @client.setbit("key3", 2, 1)
        @client.setbit("key3", 4, 1)
        @client.setbit("key3", 5, 1)
        @client.setbit("key3", 6, 1)

        @client.bitop("and", "dest1", "key1", "key2", "key3").should be == 1
        @client.bitcount("dest1").should be == 2
        @client.getbit("dest1", 1).should be == 0
        @client.getbit("dest1", 2).should be == 1
        @client.getbit("dest1", 3).should be == 0
        @client.getbit("dest1", 4).should be == 1
        @client.getbit("dest1", 5).should be == 0
        @client.getbit("dest1", 6).should be == 0
      end
    end

    describe "xor" do
      it_should_behave_like "a bitwise operation", "xor"

      it "should apply bitwise xor operation" do
        @client.setbit("key1", 0, 0)
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 2, 0)
        @client.setbit("key1", 3, 0)

        @client.setbit("key2", 0, 1)
        @client.setbit("key2", 1, 1)
        @client.setbit("key2", 2, 1)
        @client.setbit("key2", 3, 0)

        @client.bitop("xor", "dest1", "key1", "key2").should be == 1
        @client.bitcount("dest1").should be == 2
        @client.getbit("dest1", 0).should be == 1
        @client.getbit("dest1", 1).should be == 0
        @client.getbit("dest1", 2).should be == 1
        @client.getbit("dest1", 3).should be == 0
      end

      it "should apply bitwise xor operation with empty values" do
        @client.setbit("key1", 1, 1)

        @client.bitop("xor", "dest1", "key1", "nothing_here1", "nothing_here2").should be == 1
        @client.bitcount("dest1").should be == 1
        @client.getbit("dest1", 0).should be == 0
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 2).should be == 0
      end

      it "should apply bitwise xor operation with multiple keys" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 3, 1)
        @client.setbit("key1", 5, 1)
        @client.setbit("key1", 6, 1)

        @client.setbit("key2", 2, 1)
        @client.setbit("key2", 3, 1)
        @client.setbit("key2", 4, 1)
        @client.setbit("key2", 6, 1)

        @client.bitop("xor", "dest1", "key1", "key2").should be == 1
        @client.bitcount("dest1").should be == 4
        @client.getbit("dest1", 1).should be == 1
        @client.getbit("dest1", 2).should be == 1
        @client.getbit("dest1", 3).should be == 0
        @client.getbit("dest1", 4).should be == 1
        @client.getbit("dest1", 5).should be == 1
        @client.getbit("dest1", 6).should be == 0
      end
    end

    describe "not" do
      it 'raises an argument error when not passed any keys' do
        lambda { @client.bitop("not", "destkey") }.should raise_error(Redis::CommandError)
      end

      it 'raises an argument error when not passed too many keys' do
        lambda { @client.bitop("not", "destkey", "key1", "key2") }.should raise_error(Redis::CommandError)
      end

      it "should apply bitwise negation operation" do
        @client.setbit("key1", 1, 1)
        @client.setbit("key1", 3, 1)
        @client.setbit("key1", 5, 1)

        @client.bitop("not", "dest1", "key1").should be == 1
        @client.bitcount("dest1").should be == 5
        @client.getbit("dest1", 0).should be == 1
        @client.getbit("dest1", 1).should be == 0
        @client.getbit("dest1", 2).should be == 1
        @client.getbit("dest1", 3).should be == 0
        @client.getbit("dest1", 4).should be == 1
        @client.getbit("dest1", 5).should be == 0
        @client.getbit("dest1", 6).should be == 1
        @client.getbit("dest1", 7).should be == 1
      end
    end
  end
end
