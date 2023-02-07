ARG IAMGE
ARG TAG
ARG DEVEL_TAG
ARG ARCH

FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.6.1 AS adapter
FROM public.ecr.aws/awsguru/php-beta:$DEVEL_TAG-$ARCH AS builder

# Your builders code here
# You can install or disable some extensions
# RUN pecl install intl
RUN rm -rf /opt/php/extensions/ftp.* && \
    rm -rf /opt/php/extensions/shmop.* && \
    rm -rf /opt/php/extensions/pdo_sqlite.* && \
    rm -rf /opt/php/extensions/calendar.* && \
    rm -rf /opt/php/extensions/sodium.* && \
    rm -rf /opt/php/extensions/bz2.* && \
    rm -rf /opt/php/extensions/sysvsem.* && \
    rm -rf /opt/php/extensions/sysvshm.* && \
    rm -rf /opt/php/extensions/bcmath.* && \
    rm -rf /opt/php/extensions/gd.* && \
    /lambda-runtime php_release

FROM public.ecr.aws/lambda/provided:al2

ENV IAMGE=$IAMGE
ENV TAG=$TAG

COPY --from=builder /lambda-runtime /lambda-runtime
COPY --from=builder /opt            /opt
COPY --from=adapter /lambda-adapter /opt/extensions/

# code files
COPY app /var/task/app

RUN ln -s /opt/nginx/bin/nginx /usr/bin && \
    ln -s /opt/php/bin/php /usr/bin && \
    ln -s /opt/php/bin/php-fpm /usr/bin && \
    /lambda-runtime clean_libs

ENTRYPOINT /opt/bootstrap
