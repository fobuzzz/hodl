# frozen_string_literal: true

module Wallet
  class SendFunds < ApplicationCommand
    option :contract_class, default: -> { Wallet::Validations::SendCoinsContract }
    option :action_class, default: -> { Wallet::Actions::SendCoins }

    def process!
      result = yield action_class.call(payload: payload)

      Success(result)
    end
  end
end
