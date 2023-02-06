ARG IAMGE
ARG TAG
ARG DEVEL_TAG

FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.6.1 AS adapter
FROM public.ecr.aws/awsguru/php:$DEVEL_TAG AS builder

# Your builders code here
# RUN pecl install intl
# Run this command to build production runtime
RUN /lambda-runtime php_release

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
