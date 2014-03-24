require 'spec_helper'

module FakeRedis
  describe 'time' do
    before(:each) do
      @client = Redis.new
      Time.stub(:now).and_return(Time.parse('2014-03-24 15:04:12.888888'))
    end

    it 'is an array' do
      expect(@client.time).to be_an_instance_of(Array)
    end

    it 'has two elements' do
      expect(@client.time.count).to eql 2
    end

    it 'has the current time in seconds' do
      expect(@client.time.first).to eql 1395687852
    end

    it 'has the current leftover microseconds' do
      expect(@client.time.last).to eql 888888
    end
  end
end

