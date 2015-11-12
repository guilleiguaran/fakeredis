shared_examples_for "a bitwise operation" do |operator|
  it 'raises an argument error when not passed any source keys' do
    lambda { @client.bitop(operator, "destkey") }.should raise_error(Redis::CommandError)
  end

  it "should not create destination key if nothing found" do
    @client.bitop(operator, "dest1", "nothing_here1").should be == 0
    @client.exists("dest1").should be false
  end

  it "should accept operator as a case-insensitive symbol" do
    @client.set("key1", "foobar")
    @client.bitop(operator.to_s.downcase.to_sym, "dest1", "key1")
    @client.bitop(operator.to_s.upcase.to_sym, "dest2", "key1")

    @client.get("dest1").should be == "foobar"
    @client.get("dest2").should be == "foobar"
  end

  it "should accept operator as a case-insensitive string" do
    @client.set("key1", "foobar")
    @client.bitop(operator.to_s.downcase, "dest1", "key1")
    @client.bitop(operator.to_s.upcase, "dest2", "key1")

    @client.get("dest1").should be == "foobar"
    @client.get("dest2").should be == "foobar"
  end

  it "should copy original string for single key" do
    @client.set("key1", "foobar")
    @client.bitop(operator, "dest1", "key1")

    @client.get("dest1").should be == "foobar"
  end

  it "should copy original string for single key" do
    @client.set("key1", "foobar")
    @client.bitop(operator, "dest1", "key1")

    @client.get("dest1").should be == "foobar"
  end

  it "should return length of the string stored in the destination key" do
    @client.set("key1", "foobar")
    @client.set("key2", "baz")

    @client.bitop(operator, "dest1", "key1").should be == 6
    @client.bitop(operator, "dest2", "key2").should be == 3
  end

  it "should overwrite previous value with new one" do
    @client.set("key1", "foobar")
    @client.set("key2", "baz")
    @client.bitop(operator, "dest1", "key1")
    @client.bitop(operator, "dest1", "key2")

    @client.get("dest1").should be == "baz"
  end
end
