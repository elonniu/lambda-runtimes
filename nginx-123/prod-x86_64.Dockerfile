FROM public.ecr.aws/awsguru/nginx:devel-1.23-2023.1.30.1-x86_64 AS nginx

FROM public.ecr.aws/lambda/provided:al2

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.6.0 /lambda-adapter /opt/extensions/lambda-adapter

COPY --from=nginx /opt/nginx/bin  /opt/nginx/bin
COPY --from=nginx /opt/nginx/conf /opt/nginx/conf

COPY --from=nginx /var/runtime    /var/runtime
COPY --from=nginx /opt/bootstrap  /opt/bootstrap
COPY --from=nginx /opt/extensions /opt/extensions

# code files
COPY app /var/task/app

RUN ln -s /opt/nginx/bin/nginx /usr/bin

ENTRYPOINT /var/runtime/bootstrap
