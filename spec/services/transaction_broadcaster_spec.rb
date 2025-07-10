# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionBroadcaster do
  let(:broadcaster) { described_class.new }
  let(:mock_tx) { double('Bitcoin::Tx', to_payload: double(bth: 'mock_tx_hex')) }

  describe '#broadcast' do
    context 'when primary API succeeds' do
      before do
        stub_request(:post, 'https://mempool.space/signet/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 200, body: 'txid123')
      end

      it 'broadcasts transaction successfully' do
        result = broadcaster.broadcast(mock_tx)
        expect(result).to eq('txid123')
      end
    end

    context 'when primary API fails but alternative succeeds' do
      before do
        stub_request(:post, 'https://mempool.space/signet/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:post, 'https://mutinynet.com/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 200, body: 'txid456')
      end

      it 'falls back to alternative API' do
        result = broadcaster.broadcast(mock_tx)
        expect(result).to eq('txid456')
      end
    end

    context 'when primary and alternative APIs fail but third succeeds' do
      before do
        stub_request(:post, 'https://mempool.space/signet/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:post, 'https://mutinynet.com/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:post, 'https://explorer.bc-2.jp/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 200, body: 'txid789')
      end

      it 'falls back to third API' do
        result = broadcaster.broadcast(mock_tx)
        expect(result).to eq('txid789')
      end
    end

    context 'when API returns redirect' do
      before do
        stub_request(:post, 'https://mempool.space/signet/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 302, headers: { 'Location' => 'https://mempool.space/signet/api/tx/redirect' })

        stub_request(:post, 'https://mempool.space/signet/api/tx/redirect')
          .with(body: 'mock_tx_hex')
          .to_return(status: 200, body: 'txid_redirect')
      end

      it 'follows redirect' do
        result = broadcaster.broadcast(mock_tx)
        expect(result).to eq('txid_redirect')
      end
    end

    context 'when API returns error response' do
      before do
        stub_request(:post, 'https://mempool.space/signet/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 400, body: 'Bad Request')

        stub_request(:post, 'https://mutinynet.com/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 200, body: 'txid_fallback')
      end

      it 'handles error and retries with fallback' do
        result = broadcaster.broadcast(mock_tx)
        expect(result).to eq('txid_fallback')
      end
    end

    context 'when all APIs fail' do
      before do
        stub_request(:post, 'https://mempool.space/signet/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:post, 'https://mutinynet.com/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 500, body: 'Internal Server Error')

        stub_request(:post, 'https://explorer.bc-2.jp/api/tx')
          .with(body: 'mock_tx_hex')
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an error' do
        expect { broadcaster.broadcast(mock_tx) }
          .to raise_error(StandardError, /Не удалось отправить/)
      end
    end
  end
end
