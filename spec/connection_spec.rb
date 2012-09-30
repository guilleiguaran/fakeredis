require 'spec_helper'

module FakeRedis
  describe "ConnectionMethods" do

    before(:each) do
      @client = Redis.new
    end

  if fakeredis?
    it "should authenticate to the server" do
      @client.auth("pass").should be == "OK"
    end

    it "should not error with shutdown" do
      lambda { @client.shutdown }.should_not raise_error
    end
  end

    it "should echo the given string" do
      @client.echo("something").should be == "something"
    end

    it "should ping the server" do
      @client.ping.should be == "PONG"
    end
  end
end
