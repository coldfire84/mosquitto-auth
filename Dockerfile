FROM ubuntu:18.04

LABEL maintainer="Chris Bradford <chrismbradford@gmail.com>"

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
    && make install \
    && ldconfig \
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
    && make -j "$(nproc)" \
    && install -s -m755 auth-plug.so /usr/local/src/ \
    && install -s -m755 np /usr/local/bin/ \
    && cd /usr/local/src \
    && rm -rf /usr/local/src/mosquitto-auth-plug \
    && rm -rf mosquitto-1.5.8

# Download/ set execute on /docker-entrypoint.sh
WORKDIR /
ADD docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Cleanup
RUN apt-get remove -y cmake git wget pkg-config \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/*

VOLUME ["/mosquitto/data", "/mosquitto/log"]

ENTRYPOINT ["/docker-entrypoint.sh"]

# Execute mosquitto 
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
