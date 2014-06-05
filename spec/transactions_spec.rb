require 'spec_helper'

module FakeRedis
  describe "TransactionsMethods" do
    before(:all) do
      @client = Redis.new
    end

    before(:each) do
      @client.discard rescue nil
    end

    context '#multi' do
      it "should respond with 'OK'" do
        @client.multi.should == 'OK'
      end

      it "should forbid nesting" do
        @client.multi
        lambda{@client.multi}.should raise_error(Redis::CommandError)
      end

      it "should mark the start of a transaction block" do
        transaction = @client.multi do |multi|
          multi.set("key1", "1")
          multi.set("key2", "2")
          multi.expire("key1", 123)
          multi.mget("key1", "key2")
        end

        transaction.should be == ["OK", "OK", true, ["1", "2"]]
      end
    end

    context '#discard' do
      it "should responde with 'OK' after #multi" do
        @client.multi
        @client.discard.should == 'OK'
      end

      it "can't be run outside of #multi/#exec" do
        lambda{@client.discard}.should raise_error(Redis::CommandError)
      end
    end

    context '#exec' do
      it "can't be run outside of #multi" do
        lambda{@client.exec}.should raise_error(Redis::CommandError)
      end
    end

    context 'saving up commands for later' do
      before(:each) do
        @client.multi
        @string = 'fake-redis-test:string'
        @list = 'fake-redis-test:list'
      end

      it "makes commands respond with 'QUEUED'" do
        @client.set(@string, 'string').should == 'QUEUED'
        @client.lpush(@list, 'list').should == 'QUEUED'
      end

      it "gives you the commands' responses when you call #exec" do
        @client.set(@string, 'string')
        @client.lpush(@list, 'list')
        @client.lpush(@list, 'list')

        @client.exec.should == ['OK', 1, 2]
      end

      it "does not raise exceptions, but rather puts them in #exec's response" do
        @client.set(@string, 'string')
        @client.lpush(@string, 'oops!')
        @client.lpush(@list, 'list')

        responses = @client.exec
        responses[0].should == 'OK'
        responses[1].should be_a(RuntimeError)
        responses[2].should == 1
      end
    end
  end
end
