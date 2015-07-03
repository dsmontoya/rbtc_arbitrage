require 'spec_helper'

describe RbtcArbitrage::Clients::BitsoClient do
  let(:client) { RbtcArbitrage::Clients::BitsoClient.new }
  let(:bitso) { client.interface }

  before(:each) { client.validate_env }

  describe "#balance" do
    it "fetches the balance correctly", :vcr do
      balances = bitso.balance
      client.balance.should == [balances["btc_available"].to_f, balances["mxn_available"].to_f]
    end
  end

  describe "#price" do
    [:buy, :sell].each do |action|
      it "fetches price for #{action} correctly", :vcr do
        puts client.price(action)
        client.price(action).should be_a(Float)
      end
    end
  end

  describe "#trade" do
    it "trades correctly" do
      client.instance_variable_set(:@price, 3900)

      multiple = {
        buy: 1,
        sell: -1,
      }

      bitso.should_receive(:sell).with(0.01,(3900 + 0.001 * multiple[:sell]))
      client.trade(:sell)

      client.instance_variable_set(:@price, 4100)
      bitso.should_receive(:buy).with(0.01,(4100 + 0.001 * multiple[:buy]))
      client.trade(:buy)
    end
  end

  describe "#transfer" do
    it "transfers correctly" do
      sell_client = RbtcArbitrage::Clients::BitsoClient.new
      bitso.should_receive(:bitcoin_withdrawal).with(sell_client.address, 0.01)
      client.transfer sell_client
    end
  end
end