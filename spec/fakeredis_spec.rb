require 'spec_helper'

describe FakeRedis do
  after { described_class.disable }

  describe '.enable' do
    it 'in memory connection' do
      described_class.enable
      expect(described_class.enabled?).to be_truthy
    end
  end

  describe '.disable' do
    before { described_class.enable }

    it 'in memory connection' do
      described_class.disable
      expect(described_class.enabled?).to be_falsy
    end
  end
end
