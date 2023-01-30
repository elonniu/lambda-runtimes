FROM public.ecr.aws/awsguru/devel

COPY --from=public.ecr.aws/awsguru/nginx:devel-1.23-2023.1.30.1-arm64 /opt/nginx/bin /opt/nginx/bin
COPY --from=public.ecr.aws/awsguru/nginx:devel-1.23-2023.1.30.1-arm64 /opt/nginx/conf /opt/nginx/conf
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.6.0 /lambda-adapter /opt/extensions/

ARG VERSION_PHP="8.1.14"

ADD php-runtime /usr/bin/

RUN cd /tmp && \
    echo 'Install pcre2 for PHP' && \
    curl -sL https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.40/pcre2-10.40.tar.gz | tar -xvz && \
    cd pcre2-10.40 && \
    ./configure --prefix=/usr/local/pcre2 && \
    make -j$(cat /proc/cpuinfo | grep "processor" | wc -l) && \
    make install && \
    export PKG_CONFIG_PATH=/usr/local/pcre2/lib/pkgconfig/ && \
    cd / && \
    echo 'Install PHP' && \
    curl -O https://www.php.net/distributions/php-$VERSION_PHP.tar.gz && \
    tar -zxf php-$VERSION_PHP.tar.gz && \
    cd php-$VERSION_PHP && \
    ./buildconf --force && \
    ./configure \
             --prefix=/opt/php \
             --with-config-file-path=/opt/php \
             --bindir=/opt/php/bin \
             --sbindir=/opt/php/bin \
             --with-config-file-scan-dir=/opt/php/php.d \
             --localstatedir=/tmp \
             --mandir=/tmp \
             --docdir=/tmp \
             --htmldir=/tmp \
             --dvidir=/tmp \
             --pdfdir=/tmp \
             --psdir=/tmp \
             --enable-cli \
             --enable-fpm \
             --with-fpm-user=nobody \
             --with-fpm-group=nobody \
             --enable-bcmath=shared \
             --with-bz2=shared \
             --with-pear=shared \
             --enable-ctype=shared \
             --with-curl=shared \
             --enable-dom=shared \
             --enable-exif=shared \
             --enable-fileinfo=shared \
             --enable-filter=shared \
             --enable-gd=shared \
             --with-gettext=shared \
             --with-iconv=shared \
             --with-libxml=shared \
             --enable-mbstring=shared \
             --without-mysqli \
             --enable-mysqlnd=shared \
             --enable-opcache \
             --with-openssl=shared \
             --enable-pcntl=shared \
             --with-external-pcre=shared \
             --enable-pdo=shared \
             --with-pdo-mysql=shared \
             --without-pdo-pgsql \
             --without-pdo-sqlite \
             --enable-phar=shared \
             --enable-posix=shared \
             --with-readline=shared \
             --enable-session=shared \
             --enable-simplexml=shared \
             --enable-soap=shared \
             --enable-sockets=shared \
             --enable-sysvsem=shared\
             --disable-sysvshm \
             --enable-tokenizer=shared\
             --enable-xml=shared \
             --enable-xmlreader=shared \
             --enable-xmlwriter=shared \
             --without-xsl \
             --with-zip=shared \
             --with-zlib=shared \
             && \
    make -j$(cat /proc/cpuinfo | grep "processor" | wc -l) && \
    make install && \
    for bin in $(ls /opt/php/bin); do \
        ln -s /opt/php/bin/$bin /usr/bin; \
    done && \
    \
    echo 'Change Extensions Dir' && \
    export extension_dir=$(php-config --extension-dir) && \
    mv $extension_dir /opt/php/extensions && \
    ln -s /opt/php/extensions $extension_dir && \
    \
    echo 'Enable Extensions' && \
    mkdir -p /opt/php/php.d/ && \
    extension_arr=() && \
    for so in $(ls /opt/php/extensions/*.so); do \
        if readelf --wide --syms $so | grep -q ' zend_extension_entry$'; then \
            line="zend_extension=$so"; \
        else \
            line="extension=$so"; \
        fi; \
        extension_arr+=($line); \
    done && \
    echo ${extension_arr[*]} | tr ' ' '\n' | sort -n > /opt/php/php.d/extensions.ini && \
    cat /opt/php/php.d/extensions.ini && \
    \
    yes | pecl install igbinary && \
    pecl install imagick && \
    pecl install memcached && \
    \
    cd /tmp && \
    git clone https://github.com/phpredis/phpredis.git && \
    cd phpredis &&  \
    phpize && \
    ./configure && \
    make -j$(cat /proc/cpuinfo | grep "processor" | wc -l) && \
    make install && \
    \
    cd /tmp && \
    git clone --recursive https://github.com/awslabs/aws-crt-php.git && \
    cd aws-crt-php &&  \
    phpize && \
    ./configure && \
    make -j$(cat /proc/cpuinfo | grep "processor" | wc -l) && \
    make install && \
    \
    extension_arr_new=() && \
    for so in $(ls /opt/php/extensions/*.so); do \
        if readelf --wide --syms $so | grep -q ' zend_extension_entry$'; then \
            line="zend_extension=$so"; \
        else \
            line="extension=$so"; \
        fi; \
        extension_arr_new+=($line); \
    done && \
    echo "extension_dir=/opt/php/extensions" > /opt/php/php.d/extensions.ini && \
    echo ${extension_arr_new[*]} | tr ' ' '\n' | sort -n >> /opt/php/php.d/extensions.ini && \
    cat /opt/php/php.d/extensions.ini && \
    \
    echo 'Copy Extensions Libraries' && \
    mkdir -p /opt/lib && \
    chmod +x /opt/php/extensions/* && \
    for lib in $(ls /opt/php/extensions/*.so); do \
        for lib in $(ldd $lib); do \
          if [ -f "$lib" ]; then \
            echo $lib ; \
            cp $lib /opt/lib ; \
          fi; \
        done; \
    done && \
    \
    echo 'Copy PHP Libraries' && \
    for lib in $(ldd /opt/php/bin/php); do \
        if [ -f "$lib" ]; then \
            echo $lib ; \
            cp $lib /opt/lib ; \
        fi; \
    done && \
    \
    echo 'Copy PHP-FPM Libraries' && \
    for lib in $(ldd /opt/php/bin/php-fpm); do \
        if [ -f "$lib" ]; then \
            echo $lib ; \
            cp $lib /opt/lib ; \
        fi; \
    done && \
    \
    echo 'Clean Cache' && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /php-$VERSION_PHP

# config files
ADD nginx/conf/nginx.conf      /opt/nginx/conf/nginx.conf
ADD php/php.ini                /opt/php/php.ini
ADD php/etc/php-fpm.conf       /opt/php/etc/php-fpm.conf

# code files
COPY app /var/task/app

COPY runtime/bootstrap /opt/bootstrap

COPY runtime/bootstrap /var/runtime/bootstrap

RUN chmod 0755 /opt/bootstrap  \
    && chmod 0755 /var/runtime/bootstrap

ENTRYPOINT /var/runtime/bootstrap
