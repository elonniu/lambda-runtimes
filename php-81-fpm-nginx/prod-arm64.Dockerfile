FROM public.ecr.aws/awsguru/php:devel-81-2023.1.30.1-arm64 AS builder

# Your builders code here
# RUN pecl install intl

# Run this command to build production runtime to /opt and /layer.zip
RUN php-runtime

FROM public.ecr.aws/lambda/provided:al2

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.6.0 /lambda-adapter /opt/extensions/
COPY --from=builder /opt /opt

# code files
COPY app /var/task/app

RUN ln -s /opt/nginx/bin/nginx /usr/bin && \
    ln -s /opt/php/bin/php /usr/bin && \
    ln -s /opt/php/bin/php-fpm /usr/bin

ENTRYPOINT /opt/bootstrap
