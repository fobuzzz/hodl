# frozen_string_literal: true

require 'net/http'
require 'json'

module Wallet
  module Actions
    class FetchBalance < ApplicationCommand
      option :contract_class, default: -> { Wallet::Validations::FetchBalanceContract }

      def process!
        address = payload[:address]
        uri = URI("https://mempool.space/signet/api/address/#{address}")
        response = Net::HTTP.get(uri)

        # Проверяем, что ответ — JSON
        if response.strip.start_with?('{', '[')
          data = JSON.parse(response)
          balance = data['chain_stats']['funded_txo_sum'] - data['chain_stats']['spent_txo_sum']

          Success(balance: balance)
        else
          Failure(errors: ["Ошибка API или адрес не найден: #{response.strip}"])
        end
      rescue StandardError => e
        Failure(errors: [e.message])
      end
    end
  end
end
