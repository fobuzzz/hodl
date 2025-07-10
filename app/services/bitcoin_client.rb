# frozen_string_literal: true

require 'bitcoin'

class BitcoinClient
  def initialize(wif)
    @key = Bitcoin::Key.from_wif(wif)
    @utxo_fetcher = UtxoFetcher.new(address)
    @transaction_builder = TransactionBuilder.new(@key)
    @transaction_broadcaster = TransactionBroadcaster.new
  end

  def address
    @key.to_p2wpkh
  end

  def utxos
    @utxo_fetcher.fetch_confirmed_utxos
  end

  def build_tx(to_address, amount)
    utxos = self.utxos
    @transaction_builder.build_transaction(utxos, to_address, amount)
  end

  def broadcast_tx(txn)
    @transaction_broadcaster.broadcast(txn)
  end
end
