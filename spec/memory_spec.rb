require 'spec_helper'

module FakeRedis
  describe 'time' do
    before(:each) do
      @client = Redis.new
      Time.stub_chain(:now, :to_f).and_return(1397845595.5139461)
    end

    it 'is an array' do
      expect(@client.time).to be_an_instance_of(Array)
    end

    it 'has two elements' do
      expect(@client.time.count).to eql 2
    end

    if fakeredis?
      it 'has the current time in seconds' do
        expect(@client.time.first).to eql 1397845595
      end

      it 'has the current leftover microseconds' do
        expect(@client.time.last).to eql 513946
      end
    end
  end
end
