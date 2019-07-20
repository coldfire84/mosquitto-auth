FROM alpine:3.9.2

LABEL maintainer="Chris Bradford <chrismbradford@gmail.com>"

<<<<<<< HEAD
# Install Dependencies / Required Services
RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get install -y \
    pkg-config \
    cmake \
    git \
    wget \
    libwrap0-dev \
    libssl-dev \
    libc-ares-dev \
    uuid-dev \
    xsltproc 

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
RUN addgroup --system --gid 1883 mosquitto \
    && adduser --system --uid 1883 --group mosquitto \
    && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log \
    && install -d /usr/sbin/ \
    && install -s -m755 /usr/local/src/mosquitto-1.5.8/src/mosquitto /usr/sbin/mosquitto \
    && install -s -m755 /usr/local/src/mosquitto-1.5.8/src/mosquitto_passwd /usr/bin/mosquitto_passwd \
    && install -m644 /usr/local/src/mosquitto-1.5.8/mosquitto.conf /mosquitto/config/mosquitto.conf \
    && chown -R mosquitto:mosquitto /mosquitto \
    && ldconfig

# Compile and Install Mongo-C-Driver
WORKDIR /usr/local/src
RUN wget https://github.com/mongodb/mongo-c-driver/releases/download/1.14.0/mongo-c-driver-1.14.0.tar.gz \
    && tar zxf ./mongo-c-driver-1.14.0.tar.gz \
    && cd /usr/local/src/mongo-c-driver-1.14.0/ \
    && mkdir -p cmake-build \
    && cd /usr/local/src/mongo-c-driver-1.14.0/cmake-build \
    && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .. \
    && make -j "$(nproc)" \
=======
ENV PATH=/usr/local/bin:/usr/local/sbin:$PATH

# Install Dependencies / Required Services
RUN apk --no-cache --virtual build-deps add   \
    build-base git cmake cyrus-sasl-dev util-linux-dev curl-dev c-ares-dev libressl-dev py3-sphinx libtool snappy-dev \
    && mkdir -p /usr/local/src \
    && cd /usr/local/src \
    && wget https://mosquitto.org/files/source/mosquitto-1.5.8.tar.gz \
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
       binary \
>>>>>>> alpine
    && make install \
    && cd /usr/local/src \
<<<<<<< HEAD
    && rm mongo-c-driver-1.14.0.tar.gz \
    && rm -rf mongo-c-driver-1.14.0

# Compile and Install Mosquito-Auth-Plug
WORKDIR /usr/local/src
RUN git clone --single-branch -b subscribe_check_fix https://github.com/whendonkiesfly/mosquitto-auth-plug.git \
=======
    && addgroup -S -g 1883 mosquitto 2>/dev/null \
    && adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto 2>/dev/null \
    && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log \
    && install -d /usr/sbin/ \
    && install -s -m755 /usr/local/src/mosquitto-1.5.8/src/mosquitto /usr/sbin/mosquitto \
    && install -s -m755 /usr/local/src/mosquitto-1.5.8/src/mosquitto_passwd /usr/bin/mosquitto_passwd \
    && install -m644 /usr/local/src/mosquitto-1.5.8/mosquitto.conf /mosquitto/config/mosquitto.conf \
    && chown -R mosquitto:mosquitto /mosquitto \
    && cd /usr/local/src \
    && wget https://github.com/mongodb/mongo-c-driver/releases/download/1.14.0/mongo-c-driver-1.14.0.tar.gz \
    && tar zxf ./mongo-c-driver-1.14.0.tar.gz \
    && cd /usr/local/src/mongo-c-driver-1.14.0/ \
    && mkdir -p build \
    && cd /usr/local/src/mongo-c-driver-1.14.0/build \
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
    && rm mongo-c-driver-1.14.0.tar.gz \
    && rm -rf mongo-c-driver-1.14.0 \
    && git clone --single-branch -b subscribe_check_fix https://github.com/whendonkiesfly/mosquitto-auth-plug.git \
>>>>>>> alpine
    && cd /usr/local/src/mosquitto-auth-plug \
    && cp config.mk.in config.mk \
    && sed -i "s|BACKEND_MONGO ?= no|BACKEND_MONGO ?= yes|g" config.mk \
    && sed -i "s|BACKEND_MYSQL ?= yes|BACKEND_MYSQL ?= no|g" config.mk \
    && sed -i "s|MOSQUITTO_SRC =|MOSQUITTO_SRC = /usr/local/src/mosquitto-1.5.8|g" config.mk \
<<<<<<< HEAD
    && make -j "$(nproc)" \
    && install -s -m755 auth-plug.so /usr/local/src/ \
    && install -s -m755 np /usr/local/bin/ \
    && cd /usr/local/src \
    && rm -rf /usr/local/src/mosquitto-auth-plug \
    && rm -rf mosquitto-1.5.8
=======
    && make clean \
    && make -j "$(nproc)" \
    && install -s -m755 auth-plug.so /usr/local/lib/ \
    && install -s -m755 np /usr/local/bin/ \
    && cd /usr/local/src \
    && rm -rf /usr/local/src/mosquitto-auth-plug \
    && rm -rf mosquitto-1.5.8 \
    && rm mosquitto-1.5.8.tar.gz \
    && apk --no-cache add libuuid c-ares libressl ca-certificates \
    && apk del build-deps
>>>>>>> alpine

VOLUME ["/mosquitto/data", "/mosquitto/log"]

# Set up the entry point script and default command
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME ["/mosquitto/data", "/mosquitto/log"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
