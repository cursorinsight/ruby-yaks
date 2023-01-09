# Building
# ========
#
# Use the following command to build the image:
#
# ```
# $ docker build --ssh default . -t yaks
# ```

# Target Alpine version
ARG ALPINE_VERSION=3.17

# Target Ruby version
ARG RUBY_VERSION=3.2

#===============================================================================
# Runtime
#===============================================================================

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION} AS runtime

# Data directory to store GPG keys
ARG APP_DATA_DIR=/mnt/data

# Server listener port
ARG APP_SERVER_PORT=8080

# Install git and openssh to fetch dependencies
#
# Add any other Alpine libraries needed to compile the project here.
# See https://wiki.alpinelinux.org/wiki/Local_APK_cache for details
# on the local cache and need for the symlink
RUN --mount=type=cache,id=apk-global,sharing=locked,target=/var/cache/apk \
    ln -s /var/cache/apk /etc/apk/cache && \
    apk update && \
    apk upgrade && \
    apk add --update git openssh-client build-base gnupg

# Set up workplace
WORKDIR /opt/app

# Prepare application dependencies
COPY --chown=nobody:root Gemfile Gemfile.lock .
RUN --mount=type=ssh \
    bundle install

# Copy application code (excluding entries in .dockerignore!)
COPY --chown=nobody:root . .

# Environment
ENV APP_DATA_DIR=${APP_DATA_DIR} \
    APP_SERVER_PORT=${APP_SERVER_PORT}

# Expose listener port
EXPOSE ${APP_SERVER_PORT}

# Set up volume to store GPG keys
VOLUME ${APP_DATA_DIR}

# Start application as a non-root user
USER nobody

# Set up default entrypoint and command
CMD ["/opt/app/server"]
