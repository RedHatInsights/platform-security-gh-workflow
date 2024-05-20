# This is a mock Dockerfile for testing ".github/workflows/platsec-security-workflow.yml"

FROM registry.access.redhat.com/ubi8/ubi-minimal

WORKDIR /usr/src/app

COPY . /usr/src/app/

CMD ["echo", "Hello security!"]
