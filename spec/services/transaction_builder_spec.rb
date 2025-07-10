# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionBuilder do
  let(:wif) { 'cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg' }
  let(:key) { Bitcoin::Key.from_wif(wif) }
  let(:builder) { described_class.new(key) }
  let(:to_address) { 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx' }
  let(:amount) { 1000 }

  let(:utxos) do
    [
      {
        'txid' => '3a539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0127',
        'vout' => 1,
        'value' => 7999
      }
    ]
  end

  describe '#build_transaction' do
    context 'когда UTXO доступны' do
      before do
        allow($stdout).to receive(:puts) # Подавляем отладочный вывод
      end

      it 'строит валидную транзакцию' do
        tx = builder.build_transaction(utxos, to_address, amount)

        expect(tx).to be_a(Bitcoin::Tx)
        expect(tx.in).to have(1).item
        expect(tx.out).to have(2).items # получатель + сдача
        expect(tx.out.first.value).to eq(amount)
      end

      it 'рассчитывает правильную сдачу' do
        tx = builder.build_transaction(utxos, to_address, amount)

        total_input = utxos.sum { |u| u['value'] }
        fee = tx.vsize * TransactionBuilder::SATOSHI_PER_VBYTE
        expected_change = total_input - amount - fee

        expect(tx.out.last.value).to eq(expected_change)
      end

      it 'использует правильную ставку комиссии' do
        tx = builder.build_transaction(utxos, to_address, amount)

        fee = tx.vsize * TransactionBuilder::SATOSHI_PER_VBYTE
        total_input = utxos.sum { |u| u['value'] }
        total_output = tx.out.sum(&:value)

        expect(total_input - total_output).to eq(fee)
      end
    end

    context 'когда UTXO недоступны' do
      let(:empty_utxos) { [] }

      it 'выбрасывает ошибку' do
        expect { builder.build_transaction(empty_utxos, to_address, amount) }
          .to raise_error('Нет UTXO')
      end
    end

    context 'когда недостаточно средств' do
      let(:small_utxos) do
        [
          {
            'txid' => '3a539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0127',
            'vout' => 1,
            'value' => 100 # Меньше чем сумма + комиссия
          }
        ]
      end

      before do
        allow($stdout).to receive(:puts) # Подавляем отладочный вывод
      end

      it 'выбрасывает ошибку' do
        expect { builder.build_transaction(small_utxos, to_address, 1000) }
          .to raise_error('Недостаточно средств')
      end
    end

    context 'когда точная сумма (без сдачи)' do
      let(:exact_utxos) do
        [
          {
            'txid' => '3a539b785dce7d21eda6071c92e8a808f2c805caf6e4a8d59dec45d245ab0127',
            'vout' => 1,
            'value' => 1141 # сумма (1000) + предполагаемая комиссия (141)
          }
        ]
      end

      before do
        allow($stdout).to receive(:puts) # Подавляем отладочный вывод
      end

      it 'создает транзакцию без выхода для сдачи' do
        tx = builder.build_transaction(exact_utxos, to_address, amount)

        expect(tx.out).to have(1).item # Только выход для получателя
        expect(tx.out.first.value).to eq(amount)
      end
    end
  end

  describe 'приватные методы' do
    describe '#calculate_fee' do
      it 'рассчитывает комиссию на основе размера транзакции' do
        mock_tx = double('Bitcoin::Tx', vsize: 141)
        fee = builder.send(:calculate_fee, mock_tx)

        expect(fee).to eq(141) # 141 vbytes * 1 сат/vbyte
      end
    end

    describe '#select_inputs' do
      it 'выбирает минимальные inputs для покрытия требуемой суммы' do
        inputs, total = builder.send(:select_inputs, utxos, 1000)

        expect(inputs).to have(1).item
        expect(total).to eq(7999)
        expect(inputs.first['txid']).to eq(utxos.first['txid'])
      end

      it 'выбирает несколько inputs при необходимости' do
        multi_utxos = [
          { 'txid' => 'tx1', 'vout' => 0, 'value' => 500 },
          { 'txid' => 'tx2', 'vout' => 0, 'value' => 600 }
        ]

        inputs, total = builder.send(:select_inputs, multi_utxos, 1000)

        expect(inputs).to have(2).items
        expect(total).to eq(1100)
      end
    end
  end
end
