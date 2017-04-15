module Sidekiq
  @redis = Redis.new
  def self.redis(&block)
    yield @redis
  end
end
