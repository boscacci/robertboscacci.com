# syntax=docker/dockerfile:1
FROM public.ecr.aws/aws-cli/aws-cli:2.41.1@sha256:45b0aaf9c0eabaa011bfeed4bab5407e8038dd1dc9647d2a8398f57511467ead AS awscli
FROM public.ecr.aws/docker/library/node:22-bookworm-slim@sha256:47725aca53d3295ec2d3be8f62726599b3033cc262edc2c7e429909b3ac599fc

COPY --from=awscli /usr/local/aws-cli/v2/current/dist /opt/aws-cli
RUN ln -s /opt/aws-cli/aws /usr/local/bin/aws
WORKDIR /app
COPY --chown=1000:1000 *.mjs index.html style.css Caddyfile ./
USER 1000:1000
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD ["node", "/app/cloud-health.mjs"]
ENTRYPOINT ["node"]
CMD ["/app/run.mjs"]
