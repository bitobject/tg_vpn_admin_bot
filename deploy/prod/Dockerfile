# Multi-stage build optimized for both ARM64 (M1) и AMD64 (Ubuntu)
FROM hexpm/elixir:1.18.2-erlang-27.2-debian-bookworm-20250113-slim as build

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git curl

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=placeholder
ENV GUARDIAN_SECRET_KEY=placeholder

# Copy dependency files first (for better layer caching)
COPY mix.exs mix.lock ./
COPY config ./config
COPY rel ./rel

# Create apps directory structure and copy mix.exs files
RUN mkdir -p apps/admin_api apps/core apps/telegram_api
COPY apps/admin_api/mix.exs apps/admin_api/
COPY apps/core/mix.exs apps/core/
COPY apps/telegram_api/mix.exs apps/telegram_api/

# Install and compile dependencies (cached layer)
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy application source code
COPY apps ./apps

# Compile the release
RUN mix do compile, release --overwrite

# Runtime stage
FROM debian:bookworm-slim AS runtime

# Install runtime dependencies и локаль
RUN apt-get update && apt-get install -y openssl ncurses-bin libstdc++6 curl bash ca-certificates locales \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV ELIXIR_ERL_OPTIONS="+fnu"

# Create app user
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app

# Set working directory
WORKDIR /app

# Copy release from builder
COPY --from=build --chown=app:app /app/_build/prod/rel/telegram_admin_api ./

# Create necessary directories
RUN mkdir -p /app/logs && \
    chown -R app:app /app

# Switch to app user
USER app

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Start the application
CMD ["bin/telegram_admin_api", "start"] 