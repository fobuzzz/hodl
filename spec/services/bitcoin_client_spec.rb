# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BitcoinClient do
  let(:wif) { 'cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg' }
  let(:client) { described_class.new(wif) }
  let(:mock_utxo_fetcher) { instance_double(UtxoFetcher) }
  let(:mock_transaction_builder) { instance_double(TransactionBuilder) }
  let(:mock_transaction_broadcaster) { instance_double(TransactionBroadcaster) }
  let(:mock_tx) { double('Bitcoin::Tx') }
  let(:expected_address) { 'tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz' }
  let(:to_address) { 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx' }
  let(:amount) { 1000 }
  let(:txid) { '7a28afcb289a5dc6ed7a667f12afb15f0aac3da05d80bc8530ff63c1b8765c2b' }

  let(:utxos) do
    [
      {
        'txid' => '3a539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0127',
        'vout' => 1,
        'value' => 7999
      }
    ]
  end

  before do
    allow(UtxoFetcher).to receive(:new).and_return(mock_utxo_fetcher)
    allow(TransactionBuilder).to receive(:new).and_return(mock_transaction_builder)
    allow(TransactionBroadcaster).to receive(:new).and_return(mock_transaction_broadcaster)
  end

  describe '#initialize' do
    it 'creates dependencies with correct parameters' do
      expect(UtxoFetcher).to receive(:new).with(expected_address)
      expect(TransactionBuilder).to receive(:new).with(kind_of(Bitcoin::Key))
      expect(TransactionBroadcaster).to receive(:new)

      described_class.new(wif)
    end
  end

  describe '#address' do
    it 'returns the correct Bitcoin address' do
      expect(client.address).to eq(expected_address)
    end
  end

  describe '#utxos' do
    it 'delegates to UtxoFetcher' do
      expect(mock_utxo_fetcher).to receive(:fetch_confirmed_utxos).and_return(utxos)

      result = client.utxos

      expect(result).to eq(utxos)
    end
  end

  describe '#build_tx' do
    it 'fetches UTXOs and builds transaction' do
      expect(mock_utxo_fetcher).to receive(:fetch_confirmed_utxos).and_return(utxos)
      expect(mock_transaction_builder).to receive(:build_transaction)
        .with(utxos, to_address, amount)
        .and_return(mock_tx)

      result = client.build_tx(to_address, amount)

      expect(result).to eq(mock_tx)
    end
  end

  describe '#broadcast_tx' do
    it 'delegates to TransactionBroadcaster' do
      expect(mock_transaction_broadcaster).to receive(:broadcast).with(mock_tx).and_return(txid)

      result = client.broadcast_tx(mock_tx)

      expect(result).to eq(txid)
    end
  end

  describe 'integration flow' do
    it 'coordinates all services for complete transaction flow' do
      # Setup mocks
      expect(mock_utxo_fetcher).to receive(:fetch_confirmed_utxos).and_return(utxos)
      expect(mock_transaction_builder).to receive(:build_transaction)
        .with(utxos, to_address, amount)
        .and_return(mock_tx)
      expect(mock_transaction_broadcaster).to receive(:broadcast).with(mock_tx).and_return(txid)

      # Execute flow
      tx = client.build_tx(to_address, amount)
      result_txid = client.broadcast_tx(tx)

      # Verify
      expect(tx).to eq(mock_tx)
      expect(result_txid).to eq(txid)
    end
  end
end
