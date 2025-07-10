# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  before_action :set_locale

  rescue_from(ActionController::ParameterMissing) do |exception|
    Rails.logger.info exception.full_message
    error = {}
    error[exception.param] = ['параметр обязателен']
    render json: { errors: [error] }, status: :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def set_locale
    I18n.locale = I18n.default_locale
  end

  def record_not_found
    render json: { error: 'Запись не найдена' }, status: :not_found
  end
end
