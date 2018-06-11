FROM alpine:edge
RUN apk upgrade --update -f && apk add wget make gcc g++ perl pcre-dev zlib-dev linux-headers
WORKDIR /tmp
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_1-pre7.tar.gz
RUN wget http://nginx.org/download/nginx-1.15.0.tar.gz
RUN tar xzf OpenSSL_1_1_1-pre7.tar.gz
RUN cd openssl-OpenSSL_1_1_1-pre7
RUN wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-pre7_ciphers.patch
RUN patch -p1 < openssl-equal-pre7_ciphers.patch
RUN cd ../ && tar xzf nginx-1.15.0.tar.gz && cd nginx-1.15.0
RUN ./configure --with-openssl=../openssl-OpenSSL_1_1_1-pre7 --with-openssl-opt='enable-tls13downgrade' --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module
RUN make
RUN make install
RUN apk clean && rm -rf /tmp