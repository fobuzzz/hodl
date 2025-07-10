# frozen_string_literal: true

class Api::V1::WalletController < Api::V1::BaseController
  def create_key
    result = ::Wallet::PlaceKey.call(payload: params)

    if result.success?
      render json: result.value!, status: :ok
    else
      render json: result.failure, status: :unprocessable_entity
    end
  end

  def show_balance
    result = ::Wallet::ShowBalance.call(payload: params)

    if result.success?
      render json: result.value!, status: :ok
    else
      render json: result.failure, status: :unprocessable_entity
    end
  end

  def send_funds
    result = ::Wallet::SendFunds.call(payload: params)

    if result.success?
      render json: result.value!, status: :ok
    else
      render json: result.failure, status: :unprocessable_entity
    end
  end
end
