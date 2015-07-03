module RbtcArbitrage
  module Clients
    class BitsoClient
      include RbtcArbitrage::Client

      def exchange
        :bitso
      end

      def balance
        return @balance if @balance
        balances = interface.balance
        puts "balances: #{balances['mxn_available']}"

        @balance = [balances['btc_available'].to_f, balances['mxn_available'].to_f]
      end

      def interface
        @interface ||= Bitso.new(ENV["BITSO_CLIENT_ID"], ENV["BITSO_KEY"], ENV["BITSO_SECRET"])
      end

      def validate_env
        validate_keys :bitso_key, :bitso_client_id, :bitso_secret
      end

      def price action
        return @price if @price
        action = {
          buy: 'ask',
          sell: 'bid',
        }[action]

        @price = interface.ticker[action].to_f
      end

      def trade action
        price(action) unless @price #memoize
        multiple = {
          buy: 1,
          sell: -1,
        }[action]
        price = (@price + 0.001 * multiple)
        amount = @options[:volume]
        interface.send(action, *[amount, price])
      end

      def transfer other_client
        interface.bitcoin_withdrawal(other_client.address, @options[:volume])
      end

      def address
        @address ||= interface.bitcoin_deposit_address
      end
    end
  end
end