require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "FakeRedis::StringsMethods" do

  before(:each) do
    @client = FakeRedis::Redis.new
  end

  it "should set and get a value" do
    @client.set("key1", "1")

    @client.get("key1").should == "1"
  end

  it "shouldn't get a value from an un-existing key" do
    @client.get("key2").should == nil
  end

  it "should append a value to a existing value" do
    @client.set("key1", "Hello")
    @client.append("key1", " World")

    @client.get("key1").should == "Hello World"
  end

  it "should decrement by 1 a value" do
    @client.set("counter", "1")
    @client.decr("counter")

    @client.get("counter").should == "0"
  end

  it "should decrement by a given number a value" do
    @client.set("counter", "10")
    @client.decrby("counter", "5")

    @client.get("counter").should == "5"
  end

  it "should get bits from a value" do
    @client.set("key1", "a")

    @client.getbit("key1", 1).should == "1"
    @client.getbit("key1", 2).should == "1"
    @client.getbit("key1", 3).should == "0"
    @client.getbit("key1", 4).should == "0"
    @client.getbit("key1", 5).should == "0"
    @client.getbit("key1", 6).should == "0"
    @client.getbit("key1", 7).should == "1"
  end

end
