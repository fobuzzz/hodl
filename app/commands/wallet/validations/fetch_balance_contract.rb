# frozen_string_literal: true

module Wallet
  module Validations
    class FetchBalanceContract < ::CommandContract
      params do
        required(:address).filled(:string)
      end
    end
  end
end
