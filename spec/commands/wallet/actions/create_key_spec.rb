# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet::Actions::CreateKey do
  let(:wallet_dir) { Rails.root.join('spec/fixtures/wallet') }
  let(:wallet_file) { wallet_dir.join('wallet.key') }
  let(:mock_key) { double('Bitcoin::Key', to_wif: 'test_wif', to_p2wpkh: 'test_address') }

  let(:payload) do
    {
      wallet_dir: wallet_dir,
      wallet_file: wallet_file,
      key: mock_key
    }
  end

  let(:action) { described_class.new(payload: payload) }

  describe '#process!' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
    end

    context 'when file operations succeed' do
      it 'creates wallet directory' do
        expect(FileUtils).to receive(:mkdir_p).with(wallet_dir)

        action.call
      end

      it 'writes WIF to file' do
        expect(File).to receive(:write).with(wallet_file, 'test_wif')

        action.call
      end

      it 'returns success with address and WIF' do
        result = action.call

        expect(result).to be_success
        expect(result.value!).to eq(address: 'test_address', wif: 'test_wif')
      end
    end

    context 'when file operations fail' do
      before do
        allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError, 'Permission denied')
      end

      it 'returns failure with error message' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include('Permission denied')
      end
    end

    context 'when file write fails' do
      before do
        allow(File).to receive(:write).and_raise(StandardError, 'Disk full')
      end

      it 'returns failure with error message' do
        result = action.call

        expect(result).to be_failure
        expect(result.failure[:errors]).to include('Disk full')
      end
    end
  end

  describe 'validation' do
    context 'with valid payload' do
      it 'passes validation' do
        result = action.call

        expect(result).to be_success
      end
    end
  end
end
