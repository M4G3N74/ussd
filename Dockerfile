# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20250317-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.18.3-erlang-27.3-debian-bullseye-20250317-slim
#
ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.3
ARG DEBIAN_VERSION=bullseye-20250317-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"

# App builder stage
FROM ${BUILDER_IMAGE} as app_builder

# Install build dependencies with standard apt commands
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set memory-related environment variables for mix and erlang
ENV ERL_FLAGS="+MBas aoffcbf +MHas aoffcbf +MBlmbcs 512 +MHlmbcs 512 +MMmcs 30"
ENV MIX_ENV=prod

# Install hex + rebar with retry logic
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy only necessary files for dependency installation
COPY mix.exs mix.lock ./
COPY config config

# Get and compile dependencies with memory optimization
RUN mix deps.unlock --all && \
    mix deps.get --only $MIX_ENV && \
    mix deps.compile --no-debug-info

# Copy application files
COPY priv priv
COPY lib lib

# Compile the release with memory optimization flags
RUN mix compile --no-debug-info

# Copy runtime config and release files
COPY config/runtime.exs config/
COPY rel rel

# Create release with memory optimization
RUN mix release --overwrite

# Final stage - Use Debian Bullseye
FROM debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssl \
    ca-certificates \
    inotify-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN chown nobody /app

# Environment variables
ENV MIX_ENV="prod"
ENV PHX_SERVER=true
ENV RELEASE_DISTRIBUTION="none"
# Enable runtime configuration through environment variables
ENV RELEASE_NODE="kp_ussd_rel@127.0.0.1"

# Copy release
COPY --from=app_builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/kp_ussd_rel ./

USER nobody

# Use a shell to start the release so environment variables are properly expanded
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/app/bin/kp_ussd_rel start"]
