FROM public.ecr.aws/lambda/provided:al2

ENV ARCH="linux-x86_64"
ENV VERSION_OPENSSL="1.1.1p"
ENV VERSION_PCRE2="10.40"
ENV VERSION_ZLIB="1.2.13"
ENV PKG_CONFIG_PATH=/usr/local/pcre2/lib/pkgconfig/
ENV DEVEL_RUNTIME_LOCK=TRUE

RUN yum install -y \
            https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
            https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
            yum-utils \
            epel-release \
            unzip \
            curl \
            tar \
            gzip \
            make \
            cmake \
            cmake3 \
            autoconf \
            gcc \
            gcc-c++ \
            vi \
            vim-common \
            which \
            libxslt-devel \
            libjpeg-devel \
            libpng-devel \
            freetype-devel \
            libxml2-devel \
            zlib-devel \
            glibc-devel \
            curl-devel \
            libidn-devel \
            openssl-devel \
            sqlite-devel \
            libcurl-devel \
            libpng-devel \
            libjpeg-devel \
            freetype-devel \
            libicu-devel \
            oniguruma-devel \
            libxslt-devel \
            libzstd-devel \
            ImageMagick-devel \
            libmemcached-devel \
            postgresql-devel \
            libedit-devel \
            net-snmp-devel \
            libsodium-devel \
            pcre2-devel  \
            enchant-devel  \
            libffi-devel \
            gmp-devel \
            libmcrypt-devel \
            mhash-devel \
            libtidy-devel \
            pam-devel \
            openldap-devel \
            libiodbc-devel \
            postgresql-devel \
            readline-devel \
            net-snmp-devel \
            libzip-devel \
            glibc-static \
            msgpack-devel \
    && export CPU_NUM=$(cat /proc/cpuinfo | grep "processor" | wc -l) \
    && cd /tmp \
    && echo '---- Configure openssl' \
    && curl -sL https://www.openssl.org/source/openssl-${VERSION_OPENSSL}.tar.gz | tar -xvz > /dev/null \
    && cd openssl-${VERSION_OPENSSL} \
    && ./Configure ${ARCH} --prefix=/tmp/openssl \
    && echo '---- Install openssl' \
    && make -j$CPU_NUM \
    && make install \
    && echo '---- Install pcre2' \
    && cd /tmp \
    && curl -sL https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${VERSION_PCRE2}/pcre2-${VERSION_PCRE2}.tar.gz | tar -xvz > /dev/null \
    && cd pcre2-${VERSION_PCRE2} \
    && ./configure --prefix=/usr/local/pcre2 \
    && make -j$CPU_NUM \
    && make install \
    && echo '---- Install zlib' \
    && cd /tmp \
    && curl -sL https://zlib.net/zlib-${VERSION_ZLIB}.tar.gz | tar -xvz > /dev/null \
    && cd zlib-${VERSION_ZLIB} \
    && ./configure --prefix=/tmp/zlib \
    && make -j$CPU_NUM \
    && make install \
    && echo '---- Install LDAP' \
    && yum install -y openldap-devel \
    && cp -frp /usr/lib64/libldap* /usr/lib/ \
    && echo '---- Install development tools to compile' \
    && yum groupinstall -y "Development Tools" \
    && echo '---- Remove cache' \
    && yum clean all \
    && rm -rf /var/cache/yum

ADD lambda-runtime /
ADD php-runtime /
