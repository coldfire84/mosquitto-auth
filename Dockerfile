FROM alpine:latest

LABEL maintainer="Chris Bradford <chrismbradford@gmail.com>"

ENV PATH=/usr/local/bin:/usr/local/sbin:$PATH

# Install Dependencies / Required Services
RUN apk --no-cache --virtual build-deps add   \
    build-base git cmake cyrus-sasl-dev util-linux-dev curl-dev c-ares-dev libressl-dev py3-sphinx libtool snappy-dev \
    && mkdir -p /usr/local/src \
    && cd /usr/local/src \
    && wget https://mosquitto.org/files/source/mosquitto-1.6.8.tar.gz \
    && tar xvzf ./mosquitto-1.6.8.tar.gz \
    && cd mosquitto-1.6.8 \
    && make -j "$(nproc)" \
       CFLAGS="-Wall -O2 -flto"  \
       WITH_SRV=yes \
       WITH_ADNS=no \
       WITH_DOCS=no \
       WITH_MEMORY_TRACKING=no \
       WITH_TLS_PSK=no \
       WITH_WEBSOCKETS=no \
       install \
    && cd /usr/local/src \
    && addgroup -S -g 1883 mosquitto 2>/dev/null \
    && adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto 2>/dev/null \
    && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log \
    && install -d /usr/sbin/ \
    && install -s -m755 /usr/local/src/mosquitto-1.6.8/src/mosquitto /usr/sbin/mosquitto \
    && install -s -m755 /usr/local/src/mosquitto-1.6.8/src/mosquitto_passwd /usr/bin/mosquitto_passwd \
    && install -m644 /usr/local/src/mosquitto-1.6.8/mosquitto.conf /mosquitto/config/mosquitto.conf \
    && chown -R mosquitto:mosquitto /mosquitto \
    && cd /usr/local/src \
    && wget https://github.com/mongodb/mongo-c-driver/releases/download/1.15.3/mongo-c-driver-1.15.3.tar.gz \
    && tar zxf ./mongo-c-driver-1.15.3.tar.gz \
    && cd /usr/local/src/mongo-c-driver-1.15.3/ \
    && mkdir -p build \
    && cd /usr/local/src/mongo-c-driver-1.15.3/build \
    && apk --no-cache add snappy cyrus-sasl \
    && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DENABLE_BSON:STRING=ON \
        -DENABLE_MONGOC:BOOL=ON \
        -DENABLE_SSL:STRING=LIBRESSL \
        -DENABLE_AUTOMATIC_INIT_AND_CLEANUP:BOOL=OFF \
        -DENABLE_MAN_PAGES:BOOL=OFF \
        -DENABLE_EXAMPLES:BOOL=OFF \
        -DSPHINX_EXECUTABLE:STRING=/usr/bin/sphinx-build-3 \
        -DCMAKE_SKIP_RPATH=ON .. \
    && make -j "$(nproc)" \
    && make install \
    && cd /usr/local/src \
    && rm mongo-c-driver-1.15.3.tar.gz \
    && rm -rf mongo-c-driver-1.15.3 \
    && git clone --single-branch -b master https://github.com/coldfire84/mosquitto-auth-plug.git \
    && cd /usr/local/src/mosquitto-auth-plug \
    && cp config.mk.in config.mk \
    && sed -i "s|BACKEND_MONGO ?= no|BACKEND_MONGO ?= yes|g" config.mk \
    && sed -i "s|BACKEND_MYSQL ?= yes|BACKEND_MYSQL ?= no|g" config.mk \
    && sed -i "s|MOSQUITTO_SRC =|MOSQUITTO_SRC = /usr/local/src/mosquitto-1.6.8|g" config.mk \
    && make clean \
    && make -j "$(nproc)" \
    && install -s -m755 auth-plug.so /usr/local/lib/ \
    && install -s -m755 np /usr/local/bin/ \
    && cd /usr/local/src \
    && rm -rf /usr/local/src/mosquitto-auth-plug \
    && rm -rf mosquitto-1.6.8 \
    && rm mosquitto-1.6.8.tar.gz \
    && apk --no-cache add libuuid c-ares libressl ca-certificates \
    && apk del build-deps

VOLUME ["/mosquitto/data", "/mosquitto/log"]

# Set up the entry point script and default command
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME ["/mosquitto/data", "/mosquitto/log"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
