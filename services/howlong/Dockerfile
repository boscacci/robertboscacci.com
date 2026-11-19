# syntax=docker/dockerfile:1
FROM public.ecr.aws/aws-cli/aws-cli:2.41.1@sha256:45b0aaf9c0eabaa011bfeed4bab5407e8038dd1dc9647d2a8398f57511467ead AS awscli
FROM public.ecr.aws/amazonlinux/amazonlinux:2023@sha256:4c7ac3a1b220965bba39eaee0d6b1499869d832caea1293df76f34b94d2bc00e

COPY --from=awscli /usr/local/aws-cli/v2/current/dist /opt/aws-cli
RUN dnf upgrade -y && dnf install -y nodejs22 && dnf clean all \
    && ln -s /usr/bin/node-22 /usr/local/bin/node \
    && ln -s /opt/aws-cli/aws /usr/local/bin/aws
WORKDIR /app
COPY --chown=1000:1000 *.mjs index.html style.css CloudCaddyfile ./
USER 1000:1000
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD ["node", "/app/cloud-health.mjs"]
ENTRYPOINT ["node"]
CMD ["/app/run.mjs"]
