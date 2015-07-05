require 'spec_helper'

describe RbtcArbitrage::Clients::MexbtClient do
  let(:client) { RbtcArbitrage::Clients::MexbtClient.new }
  let(:mexbt) { client.interface }
  before(:each) { client.validate_env }

  describe "#balance" do
    it "fetches the balance correctly", :vcr do
      balances = mexbt.balance
      client.balance.should == [balances["usd_available"].to_f, balances["btc_available"].to_f]
    end
  end

  describe "#price" do
    [:buy, :sell].each do |action|
      it "fetches price for #{action} correctly", :vcr do
        client.price(action).should be_a(Float)
      end
    end
  end

  describe "#trade" do
    [:buy, :sell].each do |action|
      it "trades on Mexbt with #{action}" do
        client.instance_variable_set("@price", 1)
        trade_price = {
          buy: 1.001,
          sell: 0.999,
        }[action]
        mexbt_options = {amount: 0.01, price: trade_price, side: action,
          currency_pair: 'btcmxn'}
        mexbt.should_receive(:create_order).with(mexbt_options)
        client.trade(action)
      end
    end
  end

  describe "#transfer" do
    it "transfers on Mexbt correctly", :vcr do
      sell_client = RbtcArbitrage::Clients::MexbtClient.new
      Mexbt.should_receive(:transfer).with(0.01, sell_client.address)
      client.transfer sell_client
    end
  end
end