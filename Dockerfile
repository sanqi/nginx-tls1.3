FROM golang:alpine
ENV OPENSSL_VERSION=1_1_1-pre7
ENV NGINX_VERSION=1.15.0
RUN apk upgrade --update -f && apk add --no-cache wget make gcc g++ perl pcre-dev zlib-dev linux-headers
WORKDIR /tmp
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_$OPENSSL_VERSION.tar.gz && \
    tar xzf OpenSSL_$OPENSSL_VERSION.tar.gz && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar xzf nginx-$NGINX_VERSION.tar.gz && \
    cd openssl-OpenSSL_$OPENSSL_VERSION && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-pre7_ciphers.patch && \
    patch -p1 < openssl-equal-pre7_ciphers.patch && \
    cd ../nginx-$NGINX_VERSION && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_hpack_push.patch && \
    patch -p1 < nginx_hpack_push.patch && \
    ./configure --with-openssl=../openssl-OpenSSL_$OPENSSL_VERSION --with-openssl-opt=enable-tls13downgrade --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_v2_hpack_enc && \
    make && \
    make install && \
    rm -rf /tmp/*
