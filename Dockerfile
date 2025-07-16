# syntax=docker/dockerfile:1

FROM ruby:3.2.2

# Устанавливаем необходимые пакеты
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libjemalloc2 libvips sqlite3 nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app

# Копируем Gemfile и устанавливаем зависимости (для лучшего кеширования)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Копируем остальные файлы приложения
COPY . .

# Подготавливаем базу данных(на будущее, пока не используем)
RUN bundle exec rails db:prepare

# Открываем порт для Rails
EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
