FROM alpine:3.8
ENV OPENSSL_VERSION=1_1_1
ENV OPENSSL_PATCH=1.1.1-tls13_draft
ENV NGINX_VERSION=1.15.6
ARG NGX_PAGESPEED_TAG=v1.13.35.2-stable
ARG MOD_PAGESPEED_TAG=v1.13.35.2
ARG NGINX_BUILD_CONFIG="\
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-compat \
        --with-file-aio \
        --with-http_v2_module \
    "

RUN apk upgrade --update -f && apk add --no-cache apache2-dev curl wget make py-setuptools gettext-dev gperf gcc g++ perl pcre-dev zlib-dev linux-headers libgd gd-dev libxslt-dev patch apr-dev apr-util-dev build-base geoip-dev git gnupg icu-dev  libjpeg-turbo-dev libpng-dev libxslt-dev linux-headers pcre-dev tar  zlib-dev
WORKDIR /usr/src

RUN git clone https://github.com/apache/incubator-pagespeed-ngx.git \
              incubator-pagespeed-ngx \
    ;

RUN git clone -b ${MOD_PAGESPEED_TAG} \
              --recurse-submodules \
              --depth=1 \
              -c advice.detachedHead=false \
              -j`nproc` \
              https://github.com/apache/incubator-pagespeed-mod.git \
              modpagespeed \
    ;

WORKDIR /usr/src/modpagespeed

RUN cp -r /usr/src/incubator-pagespeed-ngx/docker/alpine-3.8/nginx-mainline/patches/modpagespeed/*.patch ./

RUN for i in *.patch; do printf "\r\nApplying patch ${i%%.*}\r\n"; patch -p1 < $i || exit 1; done

WORKDIR /usr/src/modpagespeed/tools/gyp
RUN ./setup.py install

WORKDIR /usr/src/modpagespeed

RUN build/gyp_chromium --depth=. \
                       -D use_system_libs=1 \
    && \
    cd /usr/src/modpagespeed/pagespeed/automatic && \
    make psol BUILDTYPE=Release \
              CFLAGS+="-I/usr/include/apr-1" \
              CXXFLAGS+="-I/usr/include/apr-1 -DUCHAR_TYPE=uint16_t" \
              -j`nproc` \
    ;

RUN mkdir -p /usr/src/ngxpagespeed/psol/lib/Release/linux/x64 && \
    mkdir -p /usr/src/ngxpagespeed/psol/include/out/Release && \
    cp -R out/Release/obj /usr/src/ngxpagespeed/psol/include/out/Release/ && \
    cp -R pagespeed/automatic/pagespeed_automatic.a /usr/src/ngxpagespeed/psol/lib/Release/linux/x64/ && \
    cp -R net \
          pagespeed \
          testing \
          third_party \
          url \
          /usr/src/ngxpagespeed/psol/include/ \
    ;
WORKDIR /usr/src
RUN git clone -b ${NGX_PAGESPEED_TAG} \
              --recurse-submodules \
              --shallow-submodules \
              --depth=1 \
              -c advice.detachedHead=false \
              -j`nproc` \
              https://github.com/apache/incubator-pagespeed-ngx.git \
              ngxpagespeed \
    ;
#COPY --from=pagespeed /usr/src/ngxpagespeed /usr/src/ngxpagespeed/
WORKDIR /tmp
RUN wget https://github.com/openssl/openssl/archive/OpenSSL_$OPENSSL_VERSION.tar.gz && \
    tar xzf OpenSSL_$OPENSSL_VERSION.tar.gz && \
    wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar xzf nginx-$NGINX_VERSION.tar.gz && \
    cd openssl-OpenSSL_$OPENSSL_VERSION && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-$OPENSSL_PATCH.patch && \
    patch -p1 < openssl-$OPENSSL_PATCH.patch && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-1.1.1-tls13_nginx_config.patch && \
    patch -p1 < openssl-1.1.1-tls13_nginx_config.patch && \
    cd ../nginx-$NGINX_VERSION && \
    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_hpack_push_1.15.3.patch && \
    patch -p1 < nginx_hpack_push_1.15.3.patch && \
#    wget https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_hpack_remove_server_header_$NGINX_VERSION.patch && \
#    patch -p1 < nginx_hpack_remove_server_header_$NGINX_VERSION.patch  && \
    ./configure --with-openssl=../openssl-OpenSSL_$OPENSSL_VERSION --with-http_v2_hpack_enc ${NGINX_BUILD_CONFIG} --add-module=/usr/src/ngxpagespeed && \
    --with-ld-opt="-Wl,-z,relro,--start-group -lapr-1 -laprutil-1 -licudata -licuuc -lpng -lturbojpeg -ljpeg" && \
    make && \
    make install && \
    rm -rf /tmp/*
