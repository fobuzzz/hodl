# frozen_string_literal: true

module Wallet
  module Validations
    class SendCoinsContract < ::CommandContract
      params do
        required(:from_wif).filled(:string)
        required(:to_address).filled(:string)
        required(:amount).filled(:integer)
      end

      rule(:amount) { key.failure('должно быть положительным') if value <= 0 }
    end
  end
end
