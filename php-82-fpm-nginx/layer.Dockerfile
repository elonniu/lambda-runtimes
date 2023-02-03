FROM public.ecr.aws/awsguru/devel AS devel
FROM public.ecr.aws/lambda/provided:al2 AS al2
FROM public.ecr.aws/lambda/provided AS provided
FROM public.ecr.aws/lambda/java:11 AS java11
FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.6.1 AS adapter
FROM public.ecr.aws/awsguru/php:devel-82-2023.2.3.3 AS builder

# Your builders code here
# RUN pecl install intl
# Run this command to build production runtime
RUN /php-runtime

FROM al2

COPY --from=builder /opt            /opt
COPY --from=builder /lambda-runtime /lambda-runtime
COPY --from=builder /usr/bin/zip    /usr/bin/zip
COPY --from=adapter /lambda-adapter /opt/extensions/

COPY --from=al2      /lib64       /libs/al2
COPY --from=al2      /usr/lib64   /libs/al2
COPY --from=al2      /var/runtime /libs/al2

COPY --from=provided /lib64       /libs/provided
COPY --from=provided /usr/lib64   /libs/provided
COPY --from=provided /var/runtime /libs/provided

COPY --from=java11   /lib64       /libs/java11
COPY --from=java11   /usr/lib64   /libs/java11
COPY --from=java11   /var/runtime /libs/java11

#RUN for lib in $(ls /opt/lib); do \
#      if [ -f "/libs/al2/$lib" ] && [ -f "/libs/provided/$lib" ] && [ -f "/libs/java11/$lib" ]; then \
#        echo "rm /opt/lib/$lib because already exists in runtime" ; \
#        rm -rf "/opt/lib/$lib" ; \
#      fi ; \
#    done

RUN /lambda-runtime zip_layer
