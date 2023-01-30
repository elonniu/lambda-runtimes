FROM public.ecr.aws/awsguru/devel

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.6.0 /lambda-adapter /opt/extensions/

RUN export ARCH="linux-aarch64" \
    && export VERSION_PCRE2="10.40" \
    && export VERSION_ZLIB="1.2.13" \
    && export VERSION_OPENSSL="1.1.1p" \
    && export VERSION_NGINX="1.23.3" \
    && export PROCESSERS=$(cat /proc/cpuinfo | grep "processor" | wc -l) \
    && echo "-------" \
    && cd /tmp \
    && curl -sL https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${VERSION_PCRE2}/pcre2-${VERSION_PCRE2}.tar.gz | tar -xvz \
    && cd pcre2-${VERSION_PCRE2} \
    && ./configure --prefix=/tmp/pcre2 \
    && make -j$PROCESSERS \
    && make install \
    && echo "-------" \
    && cd /tmp \
    && curl -sL https://zlib.net/zlib-${VERSION_ZLIB}.tar.gz | tar -xvz \
    && cd zlib-${VERSION_ZLIB} \
    && ./configure --prefix=/tmp/zlib \
    && make -j$PROCESSERS \
    && make install \
    && echo "-------" \
    && cd /tmp \
    && curl -sL https://www.openssl.org/source/openssl-${VERSION_OPENSSL}.tar.gz | tar -xvz \
    && cd openssl-${VERSION_OPENSSL} \
    && ./Configure ${ARCH} --prefix=/tmp/openssl \
    && make -j$PROCESSERS \
    && make install \
    && echo "-------" \
    && cd /tmp \
    && curl -sL https://nginx.org/download/nginx-${VERSION_NGINX}.tar.gz | tar -xvz \
    && cd nginx-${VERSION_NGINX} \
    && ./configure \
       --prefix=/opt/nginx \
       --sbin-path=/opt/nginx/bin/nginx \
       --modules-path=/opt/nginx/modules \
       --pid-path=/tmp/nginx.pid \
       --error-log-path=/dev/stderr \
       --http-log-path=/dev/stdout \
       --http-client-body-temp-path=/tmp/client_body_temp \
       --http-proxy-temp-path=/tmp/proxy_temp \
       --http-fastcgi-temp-path=/tmp/fastcgi_temp \
       --http-uwsgi-temp-path=/tmp/uwsgi_temp \
       --http-scgi-temp-path=/tmp/scgi_temp \
       --with-pcre=../pcre2-${VERSION_PCRE2} \
       --with-zlib=../zlib-${VERSION_ZLIB} \
       --with-openssl=../openssl-${VERSION_OPENSSL} \
       --with-http_ssl_module \
       --with-stream \
    && make -j$PROCESSERS \
    && make install \
    && echo "-------" \
    && ln -s /opt/nginx/bin/nginx /usr/bin \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /tmp/*

# config files
ADD nginx/conf/nginx.conf /opt/nginx/conf/nginx.conf

# code files
COPY app /var/task/app

COPY runtime/bootstrap /opt/bootstrap

COPY runtime/bootstrap /var/runtime/bootstrap

RUN chmod 0755 /opt/bootstrap  \
    && chmod 0755 /var/runtime/bootstrap

ENTRYPOINT /var/runtime/bootstrap
