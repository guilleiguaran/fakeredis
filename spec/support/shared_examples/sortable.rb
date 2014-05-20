shared_examples_for "a sortable" do
  it 'returns empty array on nil' do
    @client.sort(nil).should == []
  end

  context 'ordering' do
    it 'orders ascending by default' do
      @client.sort(@key).should == ['1', '2']
    end

    it 'orders by ascending when specified' do
      @client.sort(@key, :order => "ASC").should == ['1', '2']
    end

    it 'orders by descending when specified' do
      @client.sort(@key, :order => "DESC").should == ['2', '1']
    end

    it "orders by ascending when alpha is specified" do
      @client.sort(@key, :order => "ALPHA").should == ["1", "2"]
    end
  end

  context 'projections' do
    it 'projects element when :get is "#"' do
      @client.sort(@key, :get => '#').should == ['1', '2']
    end

    it 'projects through a key pattern' do
      @client.sort(@key, :get => 'fake-redis-test:values_*').should == ['a', 'b']
    end

    it 'projects through a key pattern and reflects element' do
      @client.sort(@key, :get => ['#', 'fake-redis-test:values_*']).should == [['1', 'a'], ['2', 'b']]
    end

    it 'projects through a hash key pattern' do
      @client.sort(@key, :get => 'fake-redis-test:hash_*->key').should == ['x', 'y']
    end
  end

  context 'weights' do
    it 'weights by projecting through a key pattern' do
      @client.sort(@key, :by => "fake-redis-test:weight_*").should == ['2', '1']
    end

    it 'weights by projecting through a key pattern and a specific order' do
      @client.sort(@key, :order => "DESC", :by => "fake-redis-test:weight_*").should == ['1', '2']
    end
  end

  context 'limit' do
    it 'only returns requested window in the enumerable' do
      @client.sort(@key, :limit => [0, 1]).should == ['1']
    end
  end

  context 'store' do
    it 'stores into another key' do
      @client.sort(@key, :store => "fake-redis-test:some_bucket").should == 2
      @client.lrange("fake-redis-test:some_bucket", 0, -1).should == ['1', '2']
    end

    it "stores into another key with other options specified" do
      @client.sort(@key, :store => "fake-redis-test:some_bucket", :by => "fake-redis-test:weight_*").should == 2
      @client.lrange("fake-redis-test:some_bucket", 0, -1).should == ['2', '1']
    end
  end
end
