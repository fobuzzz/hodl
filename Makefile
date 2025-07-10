# Команды разработки
.PHONY: help setup dev console bash clean

help: ## Показать это сообщение помощи
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Первоначальная настройка - установка зависимостей и подготовка базы данных
	bundle install
	bin/rails db:prepare

dev: ## Запуск сервера разработки
	bin/rails server

console: ## Открыть Rails консоль
	bin/rails console

# Команды Docker
up: ## Запуск приложения с Docker
	docker compose up --build

down: ## Остановка Docker контейнеров
	docker compose down

logs: ## Показать логи Docker
	docker compose logs -f

bash: ## Открыть bash в Docker контейнере
	docker compose run --rm app bash

docker-console: ## Открыть Rails консоль в Docker
	docker compose run --rm app rails console

migrate: ## Запуск миграций базы данных в Docker
	docker compose run --rm app rails db:migrate

# Команды тестирования
test: ## Запуск всех тестов (RSpec)
	bundle exec rspec

test-unit: ## Запуск юнит-тестов (сервисы, действия, команды)
	bundle exec rspec spec/services spec/commands

test-integration: ## Запуск интеграционных тестов (контроллеры)
	bundle exec rspec spec/controllers

test-coverage: ## Запуск тестов с отчетом о покрытии
	COVERAGE=true bundle exec rspec

test-watch: ## Запуск тестов в режиме наблюдения
	bundle exec guard

test-docker: ## Запуск тестов в Docker
	docker compose run --rm app bundle exec rspec

# Команды качества кода
lint: ## Запуск RuboCop линтера
	bundle exec rubocop

lint-fix: ## Автоисправление проблем RuboCop
	bundle exec rubocop -A

security: ## Запуск аудита безопасности с Brakeman
	bundle exec brakeman --no-pager

quality: ## Запуск всех проверок качества (линтинг + безопасность + тесты)
	make lint
	make security
	make test

# Команды Bitcoin кошелька
wallet-generate: ## Сгенерировать новый Bitcoin кошелек
	bin/rails runner "puts Wallet::PlaceKey.call.value!"

wallet-balance: ## Проверить баланс кошелька (ADDRESS=tb1q...)
	@if [ -z "$(ADDRESS)" ]; then echo "Использование: make wallet-balance ADDRESS=tb1q..."; exit 1; fi
	bin/rails runner "puts Wallet::ShowBalance.call(payload: { address: '$(ADDRESS)' }).value!"

wallet-send: ## Отправить Bitcoin (FROM_WIF=... TO_ADDRESS=... AMOUNT=...)
	@if [ -z "$(FROM_WIF)" ] || [ -z "$(TO_ADDRESS)" ] || [ -z "$(AMOUNT)" ]; then \
		echo "Использование: make wallet-send FROM_WIF=cV... TO_ADDRESS=tb1q... AMOUNT=1000"; exit 1; fi
	bin/rails runner "puts Wallet::SendFunds.call(payload: { from_wif: '$(FROM_WIF)', to_address: '$(TO_ADDRESS)', amount: $(AMOUNT) }).value!"

# Команды ревью
review: ## Полная проверка ревью - запуск всех тестов и проверок качества
	@echo "🔍 Запуск полной проверки ревью..."
	@echo "📋 1/4 Запуск линтера..."
	make lint
	@echo "🔒 2/4 Запуск аудита безопасности..."
	make security
	@echo "🧪 3/4 Запуск всех тестов..."
	make test
	@echo "📊 4/4 Генерация отчета о покрытии..."
	make test-coverage
	@echo "✅ Проверка ревью завершена!"

demo: ## Запуск демо кошелька (генерация ключа, проверка баланса, отправка средств)
	@echo "🪙 Демо Bitcoin кошелька"
	@echo "1. Генерация нового кошелька..."
	@make wallet-generate
	@echo "\n2. Проверка баланса для существующего кошелька..."
	@make wallet-balance ADDRESS=tb1qxtea348pm8vzg499n4mygevhymcgs2dqsygyqz
	@echo "\n3. Демо завершено! Используйте 'make help' для дополнительных команд."

# Команды очистки
clean: ## Очистка Docker контейнеров и томов
	docker compose down -v

prune: ## Очистка Docker системы
	docker system prune -f

reset: ## Сброс всего (очистка базы данных, перезапуск)
	bin/rails db:drop db:create db:migrate
	make dev

# Симуляция CI/CD
ci: ## Симуляция CI пайплайна
	@echo "🚀 Симуляция CI пайплайна..."
	bundle install --frozen
	make quality
	@echo "✅ CI пайплайн успешно завершен!" 