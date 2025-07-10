# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet::Actions::FetchBalance do
  let(:address) { 'tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz' }
  let(:payload) { { address: address } }
  let(:action) { described_class.new(payload: payload) }

  let(:balance_response) do
    {
      'chain_stats' => {
        'funded_txo_sum' => 10_000,
        'spent_txo_sum' => 2001
      }
    }
  end

  describe '#process!' do
    context 'when API returns valid JSON' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}")
          .to_return(status: 200, body: balance_response.to_json)
      end

      it 'calculates balance correctly' do
        result = action.call

        expect(result).to be_success
        expect(result.value![:balance]).to eq(7999) # 10000 - 2001
      end
    end

    context 'when API returns non-JSON response' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}")
          .to_return(status: 200, body: 'Not Found')
      end

      it 'returns failure with error message' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include('Ошибка API или адрес не найден: Not Found')
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}")
          .to_timeout
      end

      it 'returns failure with error message' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include(/execution expired/)
      end
    end

    context 'when API returns invalid JSON' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}")
          .to_return(status: 200, body: '{"invalid": json}')
      end

      it 'returns failure with JSON parse error' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end
  end

  describe 'validation' do
    context 'with valid address' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}")
          .to_return(status: 200, body: balance_response.to_json)
      end

      it 'passes validation' do
        result = action.call

        expect(result).to be_success
      end
    end

    context 'with missing address' do
      let(:payload) { {} }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with empty address' do
      let(:payload) { { address: '' } }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end
  end
end
