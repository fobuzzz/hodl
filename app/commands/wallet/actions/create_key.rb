# frozen_string_literal: true

module Wallet
  module Actions
    class CreateKey < ApplicationCommand
      option :contract_class, default: -> { Wallet::Validations::CreateKeyContract }

      def process!
        FileUtils.mkdir_p(@payload[:wallet_dir])
        File.write(@payload[:wallet_file], @payload[:key].to_wif)

        Success(address: @payload[:key].to_p2wpkh, wif: @payload[:key].to_wif)
      rescue StandardError => e
        Failure(errors: [e.message])
      end
    end
  end
end
