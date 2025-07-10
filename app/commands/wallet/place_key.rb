# frozen_string_literal: true

module Wallet
  class PlaceKey < ApplicationCommand
    option :contract_class, default: -> { ::Wallet::Validations::PlaceKeyContract }
    option :key_generator, default: -> { ::Wallet::Actions::CreateKey }

    def process!
      @payload[:wallet_dir] = Rails.root.join('wallet')
      @payload[:wallet_file] = @payload[:wallet_dir].join('wallet.key')
      @payload[:key] = Bitcoin::Key.generate

      result = yield key_generator.call(payload: @payload)

      Success(result)
    end
  end
end
