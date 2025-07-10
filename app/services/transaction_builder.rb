# frozen_string_literal: true

require 'bitcoin'

class TransactionBuilder
  SATOSHI_PER_VBYTE = 1

  def initialize(key)
    @key = key
  end

  def build_transaction(utxos, to_address, amount)
    raise 'Нет UTXO' if utxos.empty?

    # Создаем предварительную транзакцию для расчета размера
    temp_tx = create_temp_transaction(utxos, to_address, amount)
    estimated_fee = calculate_fee(temp_tx)

    Rails.logger.debug { "Предполагаемый размер транзакции: #{temp_tx.vsize} vbytes" }
    Rails.logger.debug { "Рассчитанная комиссия: #{estimated_fee} сатоши (#{SATOSHI_PER_VBYTE} сат/vbyte)" }

    # Выбираем inputs с учетом рассчитанной комиссии
    inputs, total = select_inputs(utxos, amount + estimated_fee)
    raise 'Недостаточно средств' if total < amount + estimated_fee

    debug_utxo_selection(utxos, inputs)

    # Создаем финальную транзакцию с точной комиссией
    tx = Bitcoin::Tx.new
    add_inputs(tx, inputs)
    add_outputs(tx, to_address, amount, total, estimated_fee)
    sign_inputs(tx, inputs)

    # Проверяем финальный размер и корректируем при необходимости
    final_fee = calculate_fee(tx)
    Rails.logger.debug { "Финальный размер транзакции: #{tx.vsize} vbytes, комиссия: #{final_fee} сатоши" }

    tx
  end

  private

  def calculate_fee(transaction)
    transaction.vsize * SATOSHI_PER_VBYTE
  end

  def create_temp_transaction(utxos, to_address, amount)
    temp_inputs = [utxos.first]
    temp_total = temp_inputs.sum { |utxo| utxo['value'] }

    temp_tx = Bitcoin::Tx.new
    add_inputs(temp_tx, temp_inputs)
    add_outputs(temp_tx, to_address, amount, temp_total, 0)
    sign_inputs(temp_tx, temp_inputs)

    temp_tx
  end

  def select_inputs(utxos, required_amount)
    total = 0
    inputs = []
    utxos.each do |utxo|
      total += utxo['value']
      inputs << utxo
      break if total >= required_amount
    end

    [inputs, total]
  end

  def add_inputs(txn, inputs)
    inputs.each do |utxo|
      reversed_txid = utxo['txid'].scan(/../).reverse.join
      tx_in = Bitcoin::TxIn.new(out_point: Bitcoin::OutPoint.new(reversed_txid, utxo['vout']))
      txn.in << tx_in
    end
  end

  def add_outputs(txn, to_address, amount, total, fee)
    # Добавляем выход для получателя
    txn.out << Bitcoin::TxOut.new(value: amount, script_pubkey: Bitcoin::Script.parse_from_addr(to_address))

    # Рассчитываем сдачу с учетом комиссии
    change = total - amount - fee
    return unless change.positive?

    # Добавляем выход для сдачи
    change_address = @key.to_p2wpkh
    txn.out << Bitcoin::TxOut.new(value: change, script_pubkey: Bitcoin::Script.parse_from_addr(change_address))
  end

  def sign_inputs(txn, inputs)
    inputs.each_with_index do |utxo, i|
      script_pubkey = Bitcoin::Script.parse_from_addr(@key.to_p2wpkh)
      sighash = txn.sighash_for_input(i, script_pubkey, sig_version: :witness_v0, amount: utxo['value'])
      sig = @key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

      txn.in[i].script_witness.stack << sig
      txn.in[i].script_witness.stack << [@key.pubkey].pack('H*')
    end
  end

  def debug_utxo_selection(utxos, inputs)
    Rails.logger.debug 'UTXO из API:'
    utxos.each { |u| Rails.logger.debug "#{u['txid']} (vout: #{u['vout']})" }
    Rails.logger.debug 'Выбранные inputs:'
    inputs.each { |u| Rails.logger.debug "#{u['txid']} (vout: #{u['vout']})" }

    return if inputs.all? { |u| utxos.any? { |x| x['txid'] == u['txid'] && x['vout'] == u['vout'] } }

    raise 'ОШИБКА: выбранные inputs не совпадают с UTXO из API!'
  end
end
