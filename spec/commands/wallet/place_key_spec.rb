# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet::PlaceKey do
  let(:payload) { {} }
  let(:mock_key_generator) { double('KeyGenerator') }
  let(:mock_key) { double('Bitcoin::Key', to_p2wpkh: 'test_address', to_wif: 'test_wif') }
  let(:expected_result) { { address: 'test_address', wif: 'test_wif' } }

  let(:command) { described_class.new(payload: payload, key_generator: mock_key_generator) }

  before do
    allow(Rails.root).to receive(:join).with('wallet').and_return(Pathname.new('/fake/wallet'))
    allow(Bitcoin::Key).to receive(:generate).and_return(mock_key)
  end

  describe '#process!' do
    context 'when key generation succeeds' do
      before do
        allow(mock_key_generator).to receive(:call).and_return(Dry::Monads::Success(expected_result))
      end

      it 'sets up wallet directory and file paths' do
        result = command.call

        expect(result).to be_success
        # Проверяем, что payload был обогащен необходимыми данными
        expect(command.instance_variable_get(:@payload)[:wallet_dir]).to eq(Pathname.new('/fake/wallet'))
        expect(command.instance_variable_get(:@payload)[:wallet_file]).to be_present
        expect(command.instance_variable_get(:@payload)[:key]).to eq(mock_key)
      end

      it 'generates new Bitcoin key' do
        expect(Bitcoin::Key).to receive(:generate)

        command.call
      end

      it 'calls key generator with enriched payload' do
        expect(mock_key_generator).to receive(:call).with(payload: hash_including(
          :wallet_dir, :wallet_file, :key
        ))

        command.call
      end

      it 'returns success with generated key data' do
        result = command.call

        expect(result).to be_success
        expect(result.value!).to eq(expected_result)
      end
    end

    context 'when key generation fails' do
      let(:error_message) { 'File system error' }

      before do
        allow(mock_key_generator).to receive(:call).and_return(Dry::Monads::Failure(errors: [error_message]))
      end

      it 'returns failure with error message' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include(error_message)
      end
    end
  end

  describe 'dependency injection' do
    it 'uses default key generator when none provided' do
      command = described_class.new(payload: payload)

      expect(command.instance_variable_get(:@key_generator)).to eq(Wallet::Actions::CreateKey)
    end

    it 'uses injected key generator' do
      custom_generator = double('CustomGenerator')
      command = described_class.new(payload: payload, key_generator: custom_generator)

      expect(command.instance_variable_get(:@key_generator)).to eq(custom_generator)
    end
  end
end
