# frozen_string_literal: true

require 'net/http'
require 'json'

class UtxoFetcher
  MEMPOOL_API = 'https://mempool.space/signet/api'
  ALTERNATIVE_API = 'https://mutinynet.com/api'
  SIGNET_EXPLORER_API = 'https://explorer.bc-2.jp/api'

  def initialize(address)
    @address = address
  end

  def fetch_confirmed_utxos
    fetch_utxos_with_fallback
  end

  private

  def fetch_utxos_with_fallback
    fetch_utxos_from_api(MEMPOOL_API)
  rescue StandardError => e
    Rails.logger.warn "Основной API UTXO не работает: #{e.message}, пробуем альтернативный..."

    begin
      fetch_utxos_from_api(ALTERNATIVE_API)
    rescue StandardError => e2
      Rails.logger.warn "Альтернативный API UTXO не работает: #{e2.message}, пробуем третий вариант..."
      fetch_utxos_from_api(SIGNET_EXPLORER_API)
    end
  end

  def fetch_utxos_from_api(api_url)
    uri = URI("#{api_url}/address/#{@address}/utxo")
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 30

    response = http.get(uri)
    response = handle_redirect(response) if redirect?(response)

    raise "HTTP #{response.code}: #{response.body}" unless response.code == '200'

    utxos = JSON.parse(response.body)
    # Возвращаем только подтвержденные UTXO
    utxos.select { |utxo| utxo['status']['confirmed'] }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise "Таймаут при получении UTXO из #{api_url}: #{e.message}"
  rescue JSON::ParserError => e
    raise "Ошибка парсинга JSON из #{api_url}: #{e.message}"
  rescue StandardError => e
    raise "Не удалось получить UTXO из #{api_url}: #{e.message}"
  end

  def redirect?(response)
    ['301', '302'].include?(response.code)
  end

  def handle_redirect(response)
    redirect_uri = URI(response['location'])
    redirect_http = Net::HTTP.new(redirect_uri.hostname, redirect_uri.port)
    redirect_http.use_ssl = true
    redirect_http.open_timeout = 15
    redirect_http.read_timeout = 30

    redirect_http.get(redirect_uri)
  end
end
