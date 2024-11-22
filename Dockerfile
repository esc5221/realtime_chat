FROM elixir:alpine

# Install dependencies
RUN apk add --no-cache \
    git \
    sqlite \
    sqlite-dev \
    build-base \
    inotify-tools

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy files
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib
COPY priv priv
COPY assets assets

# Install dependencies
RUN mix deps.get && mix deps.compile

EXPOSE 4000

CMD mix do ecto.create, ecto.migrate, phx.server
