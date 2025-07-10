# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet::Actions::SendCoins do
  let(:from_wif) { 'cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg' }
  let(:to_address) { 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx' }
  let(:amount) { 1000 }
  let(:payload) { { from_wif: from_wif, to_address: to_address, amount: amount } }
  let(:mock_bitcoin_client) { instance_double(BitcoinClient) }
  let(:mock_tx) { double('Bitcoin::Tx') }
  let(:expected_txid) { '7a28afcb289a5dc6ed7a667f12afb15f0aac3da05d80bc8530ff63c1b8765c2b' }

  let(:action) { described_class.new(payload: payload, bitcoin_client_class: mock_bitcoin_client_class) }
  let(:mock_bitcoin_client_class) { double('BitcoinClient') }

  describe '#process!' do
    context 'when transaction succeeds' do
      before do
        allow(mock_bitcoin_client_class).to receive(:new).with(from_wif).and_return(mock_bitcoin_client)
        allow(mock_bitcoin_client).to receive(:build_tx).with(to_address, amount).and_return(mock_tx)
        allow(mock_bitcoin_client).to receive(:broadcast_tx).with(mock_tx).and_return(expected_txid)
      end

      it 'creates BitcoinClient with correct WIF' do
        expect(mock_bitcoin_client_class).to receive(:new).with(from_wif)

        action.call
      end

      it 'builds transaction with correct parameters' do
        expect(mock_bitcoin_client).to receive(:build_tx).with(to_address, amount)

        action.call
      end

      it 'broadcasts transaction' do
        expect(mock_bitcoin_client).to receive(:broadcast_tx).with(mock_tx)

        action.call
      end

      it 'returns success with txid' do
        result = action.call

        expect(result).to be_success
        expect(result.value![:txid]).to eq(expected_txid)
      end
    end

    context 'when BitcoinClient raises error' do
      before do
        allow(mock_bitcoin_client_class).to receive(:new).with(from_wif).and_return(mock_bitcoin_client)
        allow(mock_bitcoin_client).to receive(:build_tx).and_raise(StandardError, 'No UTXOs')
      end

      it 'returns failure with error message' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include('No UTXOs')
      end
    end

    context 'when broadcast fails' do
      before do
        allow(mock_bitcoin_client_class).to receive(:new).with(from_wif).and_return(mock_bitcoin_client)
        allow(mock_bitcoin_client).to receive(:build_tx).with(to_address, amount).and_return(mock_tx)
        allow(mock_bitcoin_client).to receive(:broadcast_tx).and_raise(StandardError, 'Network error')
      end

      it 'returns failure with error message' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include('Network error')
      end
    end
  end

  describe 'validation' do
    context 'with valid payload' do
      it 'passes validation' do
        allow(mock_bitcoin_client_class).to receive(:new).and_return(mock_bitcoin_client)
        allow(mock_bitcoin_client).to receive_messages(build_tx: mock_tx, broadcast_tx: expected_txid)

        result = action.call

        expect(result).to be_success
      end
    end

    context 'with missing from_wif' do
      let(:payload) { { to_address: to_address, amount: amount } }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with missing to_address' do
      let(:payload) { { from_wif: from_wif, amount: amount } }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with missing amount' do
      let(:payload) { { from_wif: from_wif, to_address: to_address } }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with negative amount' do
      let(:payload) { { from_wif: from_wif, to_address: to_address, amount: -100 } }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end

    context 'with zero amount' do
      let(:payload) { { from_wif: from_wif, to_address: to_address, amount: 0 } }

      it 'fails validation' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to be_present
      end
    end
  end
end
