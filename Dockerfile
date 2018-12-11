FROM golang:alpine
ENV OPENSSL_VERSION=1_1_1a
ENV OPENSSL_PATCH=1.1.1a-tls13_draft
ENV NGINX_VERSION=1.15.7
RUN apk upgrade --update -f && apk add --no-cache wget make gcc g++ perl pcre-dev zlib-dev linux-headers libgd gd-dev libxslt-dev patch libjpeg-turbo-dev libpng-dev
WORKDIR /tmp
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_$OPENSSL_VERSION.tar.gz && \
    tar xzf OpenSSL_$OPENSSL_VERSION.tar.gz && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar xzf nginx-$NGINX_VERSION.tar.gz && \
    cd openssl-OpenSSL_$OPENSSL_VERSION && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-$OPENSSL_PATCH.patch && \
    patch -p1 < openssl-$OPENSSL_PATCH.patch && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-1.1.1a-tls13_nginx_config.patch && \
    patch -p1 < openssl-1.1.1a-tls13_nginx_config.patch && \
    cd ../nginx-$NGINX_VERSION && \
#    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_hpack_push_$NGINX_VERSION.patch && \
#    patch -p1 < nginx_hpack_push_$NGINX_VERSION.patch && \
#    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_hpack_remove_server_header_$NGINX_VERSION.patch && \
#    patch -p1 < nginx_hpack_remove_server_header_$NGINX_VERSION.patch  && \
#    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_openssl-1.1.x_renegotiation_bugfix.patch && \
#     patch -p1 < nginx_openssl-1.1.x_renegotiation_bugfix.patch && \
    ./configure --with-openssl=../openssl-OpenSSL_$OPENSSL_VERSION --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_image_filter_module --with-threads && \
    make && \
    make install && \
    rm -rf /tmp/*
