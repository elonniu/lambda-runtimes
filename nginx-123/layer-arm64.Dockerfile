FROM public.ecr.aws/awsguru/nginx:1.23-2023.1.30.1-arm64

COPY --from=public.ecr.aws/awsguru/devel:2023.1.30.1-arm64 /usr/bin/zip /usr/bin/zip

RUN cd /opt \
    && echo 'Zip Files' \
    && zip --quiet --recurse-paths /layer.zip .
