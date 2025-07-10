# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::WalletController, type: :controller do
  describe 'POST #create_key' do
    let(:params) { {} }
    let(:mock_command) { double('PlaceKey') }

    before do
      allow(Wallet::PlaceKey).to receive(:call).and_return(mock_command)
    end

    context 'when command succeeds' do
      let(:expected_result) { { address: 'test_address', wif: 'test_wif' } }

      before do
        allow(mock_command).to receive_messages(success?: true, value!: expected_result)
      end

      it 'returns success response' do
        post :create_key, params: params

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(expected_result.stringify_keys)
      end

      it 'calls PlaceKey command with params' do
        expect(Wallet::PlaceKey).to receive(:call).with(payload: kind_of(ActionController::Parameters))

        post :create_key, params: params
      end
    end

    context 'when command fails' do
      let(:error_message) { { errors: ['File system error'] } }

      before do
        allow(mock_command).to receive_messages(success?: false, failure: error_message)
      end

      it 'returns error response' do
        post :create_key, params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq(error_message.stringify_keys)
      end
    end
  end

  describe 'GET #show_balance' do
    let(:address) { 'tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz' }
    let(:params) { { address: address } }
    let(:mock_command) { double('ShowBalance') }

    before do
      allow(Wallet::ShowBalance).to receive(:call).and_return(mock_command)
    end

    context 'when command succeeds' do
      let(:expected_result) { { balance: 7999 } }

      before do
        allow(mock_command).to receive_messages(success?: true, value!: expected_result)
      end

      it 'returns success response' do
        get :show_balance, params: params

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(expected_result.stringify_keys)
      end

      it 'calls ShowBalance command with params' do
        expect(Wallet::ShowBalance).to receive(:call).with(payload: kind_of(ActionController::Parameters))

        get :show_balance, params: params
      end
    end

    context 'when command fails' do
      let(:error_message) { { errors: ['Address not found'] } }

      before do
        allow(mock_command).to receive_messages(success?: false, failure: error_message)
      end

      it 'returns error response' do
        get :show_balance, params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq(error_message.stringify_keys)
      end
    end
  end

  describe 'POST #send_funds' do
    let(:params) do
      {
        from_wif: 'cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg',
        to_address: 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',
        amount: 1000
      }
    end
    let(:mock_command) { double('SendFunds') }

    before do
      allow(Wallet::SendFunds).to receive(:call).and_return(mock_command)
    end

    context 'when command succeeds' do
      let(:expected_result) { { txid: '7a28afcb289a5dc6ed7a667f12afb15f0aac3da05d80bc8530ff63c1b8765c2b' } }

      before do
        allow(mock_command).to receive_messages(success?: true, value!: expected_result)
      end

      it 'returns success response' do
        post :send_funds, params: params

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(expected_result.stringify_keys)
      end

      it 'calls SendFunds command with params' do
        expect(Wallet::SendFunds).to receive(:call).with(payload: kind_of(ActionController::Parameters))

        post :send_funds, params: params
      end
    end

    context 'when command fails' do
      let(:error_message) { { errors: ['Insufficient funds'] } }

      before do
        allow(mock_command).to receive_messages(success?: false, failure: error_message)
      end

      it 'returns error response' do
        post :send_funds, params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq(error_message.stringify_keys)
      end
    end
  end
end
