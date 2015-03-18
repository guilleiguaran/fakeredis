require 'spec_helper'
require 'timeout' #Need to use this avoid blocking

module FakeRedis
  describe "SubscriptionMethods" do
    before(:each) do
      @client = Redis.new
    end
    
    context "publish" do
      it "should add to channels" do
        @client.publish("channel1", "val1").should be == 0
        @client.publish("channel1", "val2").should be == 0
      end
    end
    
    context "subscribe" do
      it "should get all messages from a channel" do
        @client.publish("channel1", "val1")
        @client.publish("channel1", "val2")
        @client.publish("channel2", "val3")
        
        msgs = []
        subscribe_sent = unsubscribe_sent = false
        Timeout.timeout(1) do
          @client.subscribe("channel1") do |on|
            on.subscribe do |channel|
              subscribe_sent = true
              channel.should be == "channel1"
            end
          
            on.message do |channel,msg|
              channel.should be == "channel1"
              msgs << msg
            end
            
            on.unsubscribe do
              unsubscribe_sent = true
            end
          end
        end
        
        msgs.should be == ["val1", "val2"]
        subscribe_sent.should
        unsubscribe_sent.should
      end
      
      it "should get all messages from multiple channels" do
        @client.publish("channel1", "val1")
        @client.publish("channel2", "val2")
        @client.publish("channel2", "val3")
        
        msgs = []
        Timeout.timeout(1) do
          @client.subscribe("channel1", "channel2") do |on|
            on.message do |channel,msg|
              msgs << [channel, msg]
            end
          end
        end
        
        msgs[0].should be == ["channel1", "val1"]
        msgs[1].should be == ["channel2", "val2"]
        msgs[2].should be == ["channel2", "val3"]
      end
    end
    
    context "unsubscribe" do
    end
    
    context "with patterns" do
      context "psubscribe" do
        it "should get all messages using pattern" do
          @client.publish("channel1", "val1")
          @client.publish("channel1", "val2")
          @client.publish("channel2", "val3")
          
          msgs = []
          subscribe_sent = unsubscribe_sent = false
          Timeout.timeout(1) do
            @client.psubscribe("channel*") do |on|
              on.psubscribe do |channel|
                subscribe_sent = true
              end
          
              on.pmessage do |pattern,channel,msg|
                pattern.should be == "channel*"
                msgs << msg
              end
            
              on.punsubscribe do
                unsubscribe_sent = true
              end
            end
          end
          
          msgs.should be == ["val1", "val2", "val3"]
          subscribe_sent.should
          unsubscribe_sent.should
        end
      end
      
      context "punsubscribe" do
      end
    end
  end
end