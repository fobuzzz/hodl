# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet::SendFunds do
  let(:from_wif) { 'cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg' }
  let(:to_address) { 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx' }
  let(:amount) { 1000 }
  let(:payload) { { from_wif: from_wif, to_address: to_address, amount: amount } }
  let(:mock_action) { double('SendCoins') }
  let(:expected_result) { { txid: '7a28afcb289a5dc6ed7a667f12afb15f0aac3da05d80bc8530ff63c1b8765c2b' } }

  let(:command) { described_class.new(payload: payload, action_class: mock_action) }

  describe '#process!' do
    context 'when action succeeds' do
      before do
        allow(mock_action).to receive(:call).and_return(Dry::Monads::Success(expected_result))
      end

      it 'calls action with payload' do
        expect(mock_action).to receive(:call).with(payload: payload)

        command.call
      end

      it 'returns success with transaction data' do
        result = command.call

        expect(result).to be_success
        expect(result.value!).to eq(expected_result)
      end
    end

    context 'when action fails' do
      let(:error_message) { { errors: ['Insufficient funds'] } }

      before do
        allow(mock_action).to receive(:call).and_return(Dry::Monads::Failure(error_message))
      end

      it 'returns failure with error message' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure).to eq(error_message)
      end
    end
  end

  describe 'dependency injection' do
    it 'uses default action when none provided' do
      command = described_class.new(payload: payload)

      expect(command.instance_variable_get(:@action_class)).to eq(Wallet::Actions::SendCoins)
    end

    it 'uses injected action' do
      custom_action = double('CustomAction')
      command = described_class.new(payload: payload, action_class: custom_action)

      expect(command.instance_variable_get(:@action_class)).to eq(custom_action)
    end
  end

  describe 'validation' do
    context 'with valid payload' do
      before do
        allow(mock_action).to receive(:call).and_return(Dry::Monads::Success(expected_result))
      end

      it 'passes validation' do
        result = command.call

        expect(result).to be_success
      end
    end

    context 'with missing from_wif' do
      let(:payload) { { to_address: to_address, amount: amount } }

      it 'fails validation' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with missing to_address' do
      let(:payload) { { from_wif: from_wif, amount: amount } }

      it 'fails validation' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with missing amount' do
      let(:payload) { { from_wif: from_wif, to_address: to_address } }

      it 'fails validation' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with invalid amount' do
      let(:payload) { { from_wif: from_wif, to_address: to_address, amount: 0 } }

      it 'fails validation' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end
  end
end
