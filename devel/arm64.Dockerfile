FROM public.ecr.aws/lambda/provided:al2-arm64

# For check lib
COPY --from=public.ecr.aws/lambda/provided:al2 /usr/lib64 /bak/usr/lib64

# For check layer
RUN touch /devel_runtime_lock

RUN yum install -y \
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
        msgpack-devel

# for ldap
RUN yum install -y openldap-devel &&  \
    cp -frp /usr/lib64/libldap* /usr/lib/

# Install development tools to compile extra PHP extensions
RUN yum groupinstall -y "Development Tools"
