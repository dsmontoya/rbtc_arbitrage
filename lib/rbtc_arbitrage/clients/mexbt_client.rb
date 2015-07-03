module RbtcArbitrage
  module Clients
    class MexbtClient
      include RbtcArbitrage::Client

      def balance
        return @balance if @balance
        balances = interface.balance
        @balance = [balances[0].to_f, balances[1].to_f]
      end

      def validate_env
        validate_keys :mexbt_public_key, :mexbt_private_key, :mexbt_user_id
        Mexbt.configure do |config|
          config.public_key = ENV['MEXBT_PUBLIC_KEY']
          config.private_key = ENV['MEXBT_PRIVATE_KEY']
          config.user_id = ENV['MEXBT_USER_ID'] # Your registered email address
        end
      end

      def exchange
        :mexbt
      end

      def interface
        @interface ||= Mexbt::Account.new
      end

      def price action
        return @price if @price
        action = {
          buy: :ask,
          sell: :bid,
        }[action]
        @price = Mexbt.ticker[action].to_f
      end

      def trade action
        price(action) unless @price #memoize
        multiple = {
          buy: 1,
          sell: -1
        }[action]
        mexbt_options = {
          price: (@price + 0.001 * multiple),
          amount: @options[:volume],
          side: action,
          currency_pair: 'btcmxn'
        }

        interface.create_order(mexbt_options)
      end

      def transfer other_client
        Mexbt.transfer(@options[:volume], other_client.address)
      end
    end
  end
end