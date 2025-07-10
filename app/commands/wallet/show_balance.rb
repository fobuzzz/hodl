# frozen_string_literal: true

module Wallet
  class ShowBalance < ApplicationCommand
    option :contract_class, default: -> { Wallet::Validations::FetchBalanceContract }
    option :action_class, default: -> { Wallet::Actions::FetchBalance }

    def process!
      result = yield action_class.call(payload: payload)

      Success(result)
    end
  end
end
