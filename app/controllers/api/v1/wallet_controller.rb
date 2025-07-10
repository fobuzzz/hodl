# frozen_string_literal: true

class Api::V1::WalletController < Api::V1::BaseController
  def create_key
    result = ::Wallet::PlaceKey.call(payload: create_key_params)

    if result.success?
      render json: result.value!, status: :ok
    else
      render json: result.failure, status: :unprocessable_entity
    end
  end

  def show_balance
    result = ::Wallet::ShowBalance.call(payload: show_balance_params)

    if result.success?
      render json: result.value!, status: :ok
    else
      render json: result.failure, status: :unprocessable_entity
    end
  end

  def send_funds
    result = ::Wallet::SendFunds.call(payload: send_funds_params)

    if result.success?
      render json: result.value!, status: :ok
    else
      render json: result.failure, status: :unprocessable_entity
    end
  end

  private

  def create_key_params
    params.permit.to_h
  end

  def show_balance_params
    params.permit(:address).to_h
  end

  def send_funds_params
    params.permit(:from_wif, :to_address, :amount).to_h
  end
end
