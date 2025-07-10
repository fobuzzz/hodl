# frozen_string_literal: true

# Настройка Bitcoin для работы с тестовой сетью Signet
require 'bitcoin'
Bitcoin.chain_params = :signet
