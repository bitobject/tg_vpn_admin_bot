# Dev Dockerfile for ARM (multiarch)
FROM hexpm/elixir:1.18.2-erlang-27.2-debian-bookworm-20250113-slim as build

RUN apt-get update && apt-get install -y build-essential git curl

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=dev

COPY mix.exs mix.lock ./
COPY config ./config

RUN mkdir -p apps/admin_api apps/core apps/telegram_api
COPY apps/admin_api/mix.exs apps/admin_api/
COPY apps/core/mix.exs apps/core/
COPY apps/telegram_api/mix.exs apps/telegram_api/

RUN mix deps.get && mix deps.compile
COPY apps ./apps

RUN mix do compile

FROM debian:bookworm-slim as runtime

RUN apt-get update && apt-get install -y openssl ncurses-bin libstdc++6 curl bash ca-certificates locales \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV ELIXIR_ERL_OPTIONS="+fnu"

RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app

WORKDIR /app
COPY --from=build --chown=app:app /app ./
RUN mkdir -p /app/logs && chown -R app:app /app
USER app
EXPOSE 4000
CMD ["iex", "-S", "mix"]
