FROM public.ecr.aws/awsguru/devel

COPY --from=public.ecr.aws/awsguru/nginx /opt /opt
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.6.1 /lambda-adapter /opt/extensions/

ENV VERSION_PHP="8.2.2"

RUN cd /tmp && \
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
      --without-bcmath \
      --without-bz2 \
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
      --enable-soap=shared \
      --enable-sockets=shared \
      --enable-sysvsem=shared\
      --disable-sysvshm \
      --enable-tokenizer=shared\
      --with-libxml=shared \
      --enable-simplexml=shared \
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
        ln -s /opt/php/bin/$bin /usr/bin ; \
    done && \
    \
    echo 'Change Extensions Dir' && \
    export extension_dir=$(php-config --extension-dir) && \
    mv $extension_dir /opt/php/extensions && \
    ln -s /opt/php/extensions $extension_dir && \
    \
    /php-runtime enable_extensions && \
    \
    yes | pecl install igbinary && \
    pecl install imagick && \
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
    /php-runtime enable_extensions && \
    \
    echo 'Copy Extensions Libraries' && \
    mkdir -p /opt/lib && \
    chmod +x /opt/php/extensions/* && \
    for lib in $(ls /opt/php/extensions/*.so); do \
        /lambda-runtime copy_libs $lib ; \
    done && \
    \
    echo 'Copy PHP Libraries' && \
    /lambda-runtime copy_libs /opt/php/bin/php && \
    /lambda-runtime copy_libs /opt/php/bin/php-fpm && \
    \
    echo 'Clean Cache' && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /tmp/*

# config files
ADD nginx/conf/nginx.conf      /opt/nginx/conf/nginx.conf
ADD php/php.ini                /opt/php/php.ini
ADD php/etc/php-fpm.conf       /opt/php/etc/php-fpm.conf

# code files
COPY app /var/task/app

COPY runtime/bootstrap /opt/bootstrap

# Copy files to /var/runtime to support deploying as a Docker image
COPY runtime/bootstrap /var/runtime/bootstrap

RUN chmod 0755 /opt/bootstrap  \
    && chmod 0755 /var/runtime/bootstrap

ENTRYPOINT /var/runtime/bootstrap
