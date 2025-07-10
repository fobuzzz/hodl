# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet::ShowBalance do
  let(:address) { 'tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz' }
  let(:payload) { { address: address } }
  let(:mock_action) { double('FetchBalance') }
  let(:expected_result) { { balance: 7999 } }

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

      it 'returns success with balance data' do
        result = command.call

        expect(result).to be_success
        expect(result.value!).to eq(expected_result)
      end
    end

    context 'when action fails' do
      let(:error_message) { { errors: ['Address not found'] } }

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

      expect(command.instance_variable_get(:@action_class)).to eq(Wallet::Actions::FetchBalance)
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

    context 'with invalid payload' do
      let(:payload) { { address: '' } }

      it 'fails validation' do
        result = command.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end
  end
end
