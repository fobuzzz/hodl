# frozen_string_literal: true

module Wallet
  module Actions
    class SendCoins < ApplicationCommand
      option :contract_class, default: -> { Wallet::Validations::SendCoinsContract }
      option :bitcoin_client_class, default: -> { BitcoinClient }

      def process!
        client = bitcoin_client_class.new(payload[:from_wif])
        tx = client.build_tx(payload[:to_address], payload[:amount])
        txid = client.broadcast_tx(tx)

        Success(txid: txid)
      rescue StandardError => e
        Failure(errors: [e.message])
      end
    end
  end
end
