ARG VERSION

FROM public.ecr.aws/awsguru/devel AS devel
FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.6.1 AS adapter
FROM public.ecr.aws/awsguru/nginx:devel-$VERSION AS nginx

FROM public.ecr.aws/lambda/provided:al2

ENV VERSION=$VERSION

COPY --from=devel   /lambda-runtime /lambda-runtime
COPY --from=nginx   /opt            /opt
COPY --from=adapter /lambda-adapter /opt/extensions/
COPY --from=nginx   /var/runtime    /var/runtime

# code files
COPY app /var/task/app

RUN ln -s /opt/nginx/bin/nginx /usr/bin && \
    /lambda-runtime clean_libs

ENTRYPOINT /var/runtime/bootstrap
