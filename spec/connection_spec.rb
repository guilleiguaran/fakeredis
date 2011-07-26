require 'spec_helper'

module FakeRedis
  describe "ConnectionMethods" do

    before(:each) do
      @client = Redis.new
    end

    it "should authenticate to the server" do
      @client.auth("pass").should == "OK"
    end

    it "should echo the given string" do
      @client.echo("something").should == "something"
    end

    it "should ping the server" do
      @client.ping.should == "PONG"
    end
  end
end
