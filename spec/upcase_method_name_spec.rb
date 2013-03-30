require 'spec_helper'

module FakeRedis
  describe "UPCASE method name will call downcase method" do

    before do
      @client = Redis.new
    end

    it "#ZCOUNT" do
      @client.should_receive(:zcount)
      @client.ZCOUNT("key", 2, 3)
    end
  end
end
