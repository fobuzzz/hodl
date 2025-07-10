# 🪙 HODL Кошелек - Примеры

## 🚀 Быстрый старт

### 1. Настройка проекта
```bash
# Клонируем и настраиваем
git clone <repository-url>
cd hodl
make setup

# Запускаем сервер разработки
make dev
```

### 2. Генерация кошелька
```bash
# Через CLI
make wallet-generate

# Через API
curl -X POST http://localhost:3000/api/v1/wallet/create_key
```

### 3. Проверка баланса
```bash
# Через CLI
make wallet-balance ADDRESS=tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz

# Через API
curl "http://localhost:3000/api/v1/wallet/balance?address=tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz"
```

### 4. Отправка средств
```bash
# Через CLI
make wallet-send FROM_WIF=cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg TO_ADDRESS=tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx AMOUNT=1000

# Через API
curl -X POST http://localhost:3000/api/v1/wallet/send_funds \
  -H 'Content-Type: application/json' \
  -d '{
    "from_wif": "cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg",
    "to_address": "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx",
    "amount": 1000
  }'
```

## 🧪 Примеры тестирования

### Запуск всех тестов
```bash
# Полный набор тестов
make test

# С отчетом о покрытии
make test-coverage

# Только юнит-тесты
make test-unit

# Только интеграционные тесты
make test-integration
```

### Режим наблюдения
```bash
# Автоматический запуск тестов при изменении файлов
make test-watch
```

### Конкретные тесты
```bash
# Тестирование конкретного сервиса
bundle exec rspec spec/services/bitcoin_client_spec.rb

# Тестирование конкретной команды
bundle exec rspec spec/commands/wallet/place_key_spec.rb

# Тест с фокусом
bundle exec rspec spec/services/bitcoin_client_spec.rb:45
```

## 🔍 Примеры проверки качества кода

### Линтинг
```bash
# Проверка стиля кода
make lint

# Автоисправление проблем
make lint-fix

# Аудит безопасности
make security

# Все проверки качества
make quality
```

## 🏗️ Примеры архитектуры

### Использование команд в Rails консоли
```ruby
# Генерация нового кошелька
result = Wallet::PlaceKey.call
puts result.value! if result.success?

# Проверка баланса
result = Wallet::ShowBalance.call(payload: { address: 'tb1q...' })
puts result.value![:balance] if result.success?

# Отправка средств
result = Wallet::SendFunds.call(payload: {
  from_wif: 'cV...',
  to_address: 'tb1q...',
  amount: 1000
})
puts result.value![:txid] if result.success?
```

### Прямое использование сервисов
```ruby
# Использование Bitcoin клиента
client = BitcoinClient.new('cVUdoCKM9WvEjx3DUGpPNinCDmgLCabZ2k9kZ1JG4McfbmCV2VVg')
puts client.address
puts client.utxos
tx = client.build_tx('tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx', 1000)
txid = client.broadcast_tx(tx)

# Отдельные сервисы
fetcher = UtxoFetcher.new('tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz')
utxos = fetcher.fetch_confirmed_utxos

builder = TransactionBuilder.new(Bitcoin::Key.from_wif('cV...'))
tx = builder.build_transaction(utxos, 'tb1q...', 1000)

broadcaster = TransactionBroadcaster.new
txid = broadcaster.broadcast(tx)
```

## 🔧 Примеры разработки

### Добавление новых функций
```ruby
# 1. Создаем действие
class Wallet::Actions::NewFeature < ApplicationAction
  def process!
    # Реализация
    Success(result)
  rescue StandardError => e
    Failure(errors: [e.message])
  end
end

# 2. Создаем команду
class Wallet::NewCommand < ApplicationCommand
  option :action_class, default: -> { Wallet::Actions::NewFeature }
  
  def process!
    yield action_class.call(payload: @payload)
  end
end

# 3. Добавляем эндпоинт контроллера
def new_endpoint
  result = Wallet::NewCommand.call(payload: params)
  
  if result.success?
    render json: result.value!
  else
    render json: result.failure, status: :unprocessable_entity
  end
end

# 4. Добавляем тесты
RSpec.describe Wallet::Actions::NewFeature do
  # Реализация тестов
end
```

### Паттерны тестирования
```ruby
# Мокирование внешних сервисов
before do
  stub_request(:get, /mempool\.space/)
    .to_return(status: 200, body: mock_response.to_json)
end

# Мокирование зависимостей
let(:mock_service) { instance_double(SomeService) }
before do
  allow(SomeService).to receive(:new).and_return(mock_service)
  allow(mock_service).to receive(:call).and_return(expected_result)
end

# Тестирование обработки ошибок
it 'корректно обрабатывает сетевые ошибки' do
  stub_request(:get, /api/).to_timeout
  
  result = subject.call
  
  expect(result).to be_failure
  expect(result.failure[:errors]).to include(/timeout/)
end
```

## 🐳 Примеры Docker

### Разработка с Docker
```bash
# Запуск сервисов
make up

# Просмотр логов
make logs

# Открытие консоли
make docker-console

# Запуск тестов
make test-docker

# Остановка сервисов
make down
```

### Переопределение Docker Compose
```yaml
# docker-compose.override.yml
version: '3.8'
services:
  app:
    volumes:
      - .:/app
    environment:
      - RAILS_ENV=development
    ports:
      - "3000:3000"
```

## 🚨 Примеры обработки ошибок

### Ответы API с ошибками
```json
// Ошибка валидации
{
  "errors": {
    "address": ["отсутствует", "должен быть заполнен"]
  }
}

// Ошибка бизнес-логики
{
  "errors": ["Недостаточно средств"]
}

// Сетевая ошибка
{
  "errors": ["Не удалось получить UTXO: таймаут"]
}
```

### Обработка ошибок команд
```ruby
result = Wallet::SendFunds.call(payload: invalid_params)

if result.failure?
  case result.failure[:errors].first
  when /Недостаточно средств/
    # Обработка недостатка средств
  when /Неверный адрес/
    # Обработка неверного адреса
  else
    # Обработка общей ошибки
  end
end
```

## 📊 Примеры мониторинга

### Мониторинг производительности
```ruby
# Добавление замера времени к командам
class Wallet::SendFunds < ApplicationCommand
  def process!
    start_time = Time.current
    result = yield action_class.call(payload: @payload)
    duration = Time.current - start_time
    
    Rails.logger.info "SendFunds выполнено за #{duration}с"
    Success(result)
  end
end
```

### Примеры логирования
```ruby
# Структурированное логирование
Rails.logger.info "Транзакция создана", {
  txid: tx.txid,
  amount: amount,
  fee: fee,
  inputs_count: tx.in.size,
  outputs_count: tx.out.size
}
```

## 🔒 Примеры безопасности

### Санитизация входных данных
```ruby
# В контрактах валидации
rule(:amount) do
  key.failure('должно быть положительным') if value && value <= 0
  key.failure('слишком большое') if value && value > 21_000_000 * 100_000_000
end

rule(:address) do
  key.failure('неверный формат') unless value&.match?(/^tb1[a-z0-9]{39,59}$/)
end
```

### Безопасная работа с ключами
```ruby
# Никогда не логируем приватные ключи
Rails.application.config.filter_parameters += [
  :wif, :private_key, :seed, :mnemonic
]

# Безопасные права доступа к файлам
File.write(wallet_file, wif, mode: 0o600)
```

---

**Нужно больше примеров? Проверьте тестовые файлы в директории `spec/` для комплексных паттернов использования!** 