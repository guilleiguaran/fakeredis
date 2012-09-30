require 'spec_helper'

module FakeRedis
  describe "TransactionsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should mark the start of a transaction block" do
      transaction = @client.multi do
        @client.set("key1", "1")
        @client.set("key2", "2")
        @client.mget("key1", "key2")
      end

      transaction.should be == ["OK", "OK", ["1", "2"]]
    end
  end
end
