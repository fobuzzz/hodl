# frozen_string_literal: true

require 'net/http'

class TransactionBroadcaster
  MEMPOOL_API = 'https://mempool.space/signet/api'
  ALTERNATIVE_API = 'https://mutinynet.com/api'
  SIGNET_EXPLORER_API = 'https://explorer.bc-2.jp/api'

  def broadcast(txn)
    broadcast_with_fallback(txn)
  end

  private

  def broadcast_with_fallback(txn)
    broadcast_tx_to_api(MEMPOOL_API, txn)
  rescue StandardError => e
    Rails.logger.warn "Основной API отправки не работает: #{e.message}, пробуем альтернативный..."

    begin
      broadcast_tx_to_api(ALTERNATIVE_API, txn)
    rescue StandardError => e2
      Rails.logger.warn "Альтернативный API отправки не работает: #{e2.message}, пробуем третий вариант..."
      broadcast_tx_to_api(SIGNET_EXPLORER_API, txn)
    end
  end

  def broadcast_tx_to_api(api_url, txn)
    uri = URI("#{api_url}/tx")
    req = Net::HTTP::Post.new(uri)
    req.body = txn.to_payload.bth
    req.content_type = 'text/plain'

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 30

    res = http.request(req)
    res = handle_redirect(res, txn) if redirect?(res)

    raise "HTTP #{res.code}: #{res.body}" unless res.code == '200'

    res.body
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise "Таймаут при отправке в #{api_url}: #{e.message}"
  rescue StandardError => e
    raise "Не удалось отправить в #{api_url}: #{e.message}"
  end

  def redirect?(response)
    ['301', '302'].include?(response.code)
  end

  def handle_redirect(response, txn)
    redirect_uri = URI(response['location'])
    redirect_http = Net::HTTP.new(redirect_uri.hostname, redirect_uri.port)
    redirect_http.use_ssl = true
    redirect_http.open_timeout = 15
    redirect_http.read_timeout = 30

    redirect_req = Net::HTTP::Post.new(redirect_uri)
    redirect_req.body = txn.to_payload.bth
    redirect_req.content_type = 'text/plain'

    redirect_http.request(redirect_req)
  end
end
