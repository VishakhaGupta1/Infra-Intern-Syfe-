
FROM ubuntu:20.04 AS builder


ENV OPENRESTY_VERSION=1.21.4.1
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre3-dev \
    libssl-dev \
    zlib1g-dev \
    curl \
    git \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*


RUN curl -fSL https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz -o openresty.tar.gz \
    && tar -xzf openresty.tar.gz \
    && rm openresty.tar.gz


WORKDIR /openresty-${OPENRESTY_VERSION}
RUN ./configure \
    --prefix=/opt/openresty \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_stub_status_module \
    --without-http_redis2_module \
    --with-http_iconv_module \
    --with-http_postgres_module \
    -j$(nproc) \
    && make -j$(nproc) \
    && make install


FROM ubuntu:20.04


COPY --from=builder /opt/openresty /opt/openresty


RUN apt-get update && apt-get install -y \
    libpcre3 \
    libssl1.1 \
    zlib1g \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*


ENV PATH=/opt/openresty/bin:/opt/openresty/nginx/sbin:$PATH

COPY nginx.conf /opt/openresty/nginx/conf/nginx.conf


RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run


EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
