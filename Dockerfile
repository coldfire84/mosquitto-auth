FROM alpine:3.8

LABEL maintainer="Chris Bradford <chrismbradford@gmail.com>"

# Install Dependencies / Required Services
RUN set -x \
    && apk --no-cache add --virtual build-deps \
    build-base git cmake gnupg libressl-dev util-linux-dev

# Compile and Install Mosquitto 1.5.8
WORKDIR /usr/local/src
RUN wget https://mosquitto.org/files/source/mosquitto-1.5.8.tar.gz \
    && tar xvzf ./mosquitto-1.5.8.tar.gz \
    && cd mosquitto-1.5.8 \
    && make -j "$(nproc)" \
       CFLAGS="-Wall -O2 -flto" \
       WITH_SRV=yes \
       WITH_ADNS=no \
       WITH_DOCS=no \
       WITH_MEMORY_TRACKING=no \
       WITH_SHARED_LIBRARIES=no \
       WITH_SRV=no \
       WITH_STRIP=yes \
       WITH_TLS_PSK=no \
       prefix=/usr \
       binary \
    && make install

WORKDIR /usr/local/src
RUN addgroup -S -g 1883 mosquitto 2>/dev/null \
    && adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto 2>/dev/null \
    && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log \
    && install -d /usr/sbin/ \
    && install -s -m755 /usr/local/src/mosquitto-1.5.8/src/mosquitto /usr/sbin/mosquitto \
    && install -s -m755 /usr/local/src/mosquitto-1.5.8/src/mosquitto_passwd /usr/bin/mosquitto_passwd \
    && install -m644 /usr/local/src/mosquitto-1.5.8/mosquitto.conf /mosquitto/config/mosquitto.conf \
    && chown -R mosquitto:mosquitto /mosquitto

# Compile and Install Mongo-C-Driver
WORKDIR /usr/local/src
RUN wget https://github.com/mongodb/mongo-c-driver/releases/download/1.14.0/mongo-c-driver-1.14.0.tar.gz \
    && tar zxf ./mongo-c-driver-1.14.0.tar.gz \
    && cd /usr/local/src/mongo-c-driver-1.14.0/ \
    && mkdir -p cmake-build \
    && cd /usr/local/src/mongo-c-driver-1.14.0/cmake-build \
    && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .. \
    && make -j "$(nproc)" prefix=/usr \
    && make install \
    && cd /usr/local/src \
    && rm mongo-c-driver-1.14.0.tar.gz \
    && rm -rf mongo-c-driver-1.14.0

# Compile and Install Mosquito-Auth-Plug
WORKDIR /usr/local/src
RUN git clone --single-branch -b subscribe_check_fix https://github.com/whendonkiesfly/mosquitto-auth-plug.git \
    && cd /usr/local/src/mosquitto-auth-plug \
    && cp config.mk.in config.mk \
    && sed -i "s|BACKEND_MONGO ?= no|BACKEND_MONGO ?= yes|g" config.mk \
    && sed -i "s|BACKEND_MYSQL ?= yes|BACKEND_MYSQL ?= no|g" config.mk \
    && sed -i "s|MOSQUITTO_SRC =|MOSQUITTO_SRC = /usr/local/src/mosquitto-1.5.8|g" config.mk \
    && export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig/ \
    && make -j "$(nproc)" \
    && cp auth-plug.so /usr/local/src \
    && cp np /usr/local/bin/ && chmod +x /usr/local/bin/np \
    && cd /usr/local/src \
    && rm -rf /usr/local/src/mosquitto-auth-plug \
    && rm -rf mosquitto-1.5.8

# Cleanup
RUN apk --no-cache add \
    libuuid \
    && apk del build-deps

VOLUME ["/mosquitto/data", "/mosquitto/log"]

# Set up the entry point script and default command
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
