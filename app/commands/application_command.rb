# frozen_string_literal: true

require 'dry/monads/do'
require 'bitcoin'

class ApplicationCommand
  extend Dry::Initializer[undefined: false]
  include Dry::Monads[:result, :do]

  option :payload, optional: true

  def self.call(...)
    new(...).call
  end

  def call
    yield validate_contract!

    result = ActiveRecord::Base.transaction(joinable: false) do
      process!
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(errors: [e.message])
  ensure
    run_after_callback if result&.success?
  end

  def run_after_callback
    return unless defined?(@@after_callback_method) && respond_to?(@@after_callback_method, true)

    ActiveRecord.after_all_transactions_commit do
      send(@@after_callback_method)
    end
  end

  def self.after_callback(method)
    @after_callback_method = method
  end

  class << self
    attr_reader :after_callback_method
  end

  def process!
    raise NotImplementedError, "Метод `#{__method__}` не реализован в `#{self.class}`. Используйте наследников."
  end

  def validate_contract!
    return Success() unless defined?(@contract_class)

    @payload = @payload.is_a?(Hash) ? @payload : @payload.to_h
    result = @contract_class.new.call(@payload)
    result.success? ? Success() : Failure(errors: result.errors.messages)
  end

  def log_error(error)
    raise error if Rails.env.test?

    Rails.logger.debug error.message
    error.backtrace.each { |line| Rails.logger.debug line }
  end
end
