require 'spec_helper'

module FakeRedis
  describe "UPCASE method name will call downcase method" do

    before do
      @client = Redis.new
    end

    it "#ZCOUNT" do
      @client.ZCOUNT("key", 2, 3).should == @client.zcount("key", 2, 3)
    end

    it "#ZSCORE" do
      @client.ZSCORE("key", 2).should == @client.zscore("key", 2)
    end
  end
end
