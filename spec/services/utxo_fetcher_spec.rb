# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UtxoFetcher do
  let(:address) { 'tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz' }
  let(:fetcher) { described_class.new(address) }

  let(:confirmed_utxos) do
    [
      {
        'txid' => '3a539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0127',
        'vout' => 1,
        'value' => 7999,
        'status' => { 'confirmed' => true }
      },
      {
        'txid' => '2b539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0128',
        'vout' => 0,
        'value' => 5000,
        'status' => { 'confirmed' => true }
      }
    ]
  end

  let(:mixed_utxos) do
    [
      {
        'txid' => '3a539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0127',
        'vout' => 1,
        'value' => 7999,
        'status' => { 'confirmed' => true }
      },
      {
        'txid' => '2b539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0128',
        'vout' => 0,
        'value' => 5000,
        'status' => { 'confirmed' => false }
      }
    ]
  end

  describe '#fetch_confirmed_utxos' do
    context 'when primary API succeeds' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
          .to_return(status: 200, body: mixed_utxos.to_json)
      end

      it 'returns only confirmed UTXOs' do
        result = fetcher.fetch_confirmed_utxos

        expect(result).to have(1).item
        expect(result.first['status']['confirmed']).to be true
      end
    end

    context 'when primary API fails but alternative succeeds' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:get, "https://mutinynet.com/api/address/#{address}/utxo")
          .to_return(status: 200, body: confirmed_utxos.to_json)
      end

      it 'falls back to alternative API' do
        result = fetcher.fetch_confirmed_utxos

        expect(result).to have(2).items
        expect(result.all? { |utxo| utxo['status']['confirmed'] }).to be true
      end
    end

    context 'when primary and alternative APIs fail but third succeeds' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:get, "https://mutinynet.com/api/address/#{address}/utxo")
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:get, "https://explorer.bc-2.jp/api/address/#{address}/utxo")
          .to_return(status: 200, body: confirmed_utxos.to_json)
      end

      it 'falls back to third API' do
        result = fetcher.fetch_confirmed_utxos

        expect(result).to have(2).items
        expect(result.all? { |utxo| utxo['status']['confirmed'] }).to be true
      end
    end

    context 'when API returns redirect' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
          .to_return(
            status: 302,
            headers: { 'Location' => "https://mempool.space/signet/api/address/#{address}/utxo/redirect" }
          )

        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo/redirect")
          .to_return(status: 200, body: confirmed_utxos.to_json)
      end

      it 'follows redirect' do
        result = fetcher.fetch_confirmed_utxos

        expect(result).to have(2).items
        expect(result.all? { |utxo| utxo['status']['confirmed'] }).to be true
      end
    end

    context 'when all APIs fail' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:get, "https://mutinynet.com/api/address/#{address}/utxo")
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:get, "https://explorer.bc-2.jp/api/address/#{address}/utxo")
          .to_return(status: 404, body: 'Not Found')
      end

      it 'raises an error' do
        expect { fetcher.fetch_confirmed_utxos }.to raise_error(StandardError, /Не удалось получить UTXO/)
      end
    end
  end
end
