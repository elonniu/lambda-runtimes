ARG DEVEL_TAG

FROM public.ecr.aws/awsguru/devel AS devel
FROM public.ecr.aws/lambda/provided:al2 AS al2
FROM public.ecr.aws/lambda/provided AS provided
FROM public.ecr.aws/lambda/java:11 AS java11
FROM public.ecr.aws/sam/emulation-java11 AS emulation
FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.6.1 AS adapter
FROM public.ecr.aws/awsguru/php:$DEVEL_TAG AS builder

COPY lambda-runtime /

# Your builders code here
# You can install or disable some extensions
# RUN pecl install intl
RUN /lambda-runtime php_release

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

COPY --from=emulation /lib64       /libs/emulation
COPY --from=emulation /usr/lib64   /libs/emulation
COPY --from=emulation /var/runtime /libs/emulation

RUN for lib in $(ls /opt/lib); do \
      if [ -f "/libs/al2/$lib" ] && \
         [ -f "/libs/provided/$lib" ] && \
         [ -f "/libs/java11/$lib" ] && \
         [ -f "/libs/emulation/$lib" ]; then \
         echo "rm /opt/lib/$lib because already exists in runtime" ; \
         rm -rf "/opt/lib/$lib" ; \
      fi ; \
    done

RUN /lambda-runtime php_zip_layer

ENTRYPOINT /bin/mv