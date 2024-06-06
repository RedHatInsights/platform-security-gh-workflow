#!/bin/bash

set -exv

IMAGE=$1
IMAGE_TAG="security-scan"
DOCKERFILE_LOCATION=$2
IMAGE_ARCHIVE="${IMAGE}-${IMAGE_TAG}.tar"

SYFT_VERSION="v0.103.1"
GRYPE_VERSION="v0.74.4"

# (Severity Options: negligible, low, medium, high, critical)
FAIL_ON_SEVERITY=$3

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

if [[ -z "$RH_REGISTRY_USER" || -z "$RH_REGISTRY_TOKEN" ]]; then
    echo "RH_REGISTRY_USER and RH_REGISTRY_TOKEN  must be set"
    exit 1
fi

# Create tmp dir to store data in during job run (do NOT store in $WORKSPACE)
export TMP_JOB_DIR=$(mktemp -d -p "$HOME" -t "jenkins-${JOB_NAME}-${BUILD_NUMBER}-XXXXXX")
echo "job tmp dir location: $TMP_JOB_DIR"

function job_cleanup() {
    echo "cleaning up job tmp dir: $TMP_JOB_DIR"
    rm -fr $TMP_JOB_DIR
}

trap job_cleanup EXIT ERR SIGINT SIGTERM

# Set up Podman Config
AUTH_CONF_DIR="${TMP_JOB_DIR}/.podman"
mkdir -p $AUTH_CONF_DIR
export REGISTRY_AUTH_FILE="$AUTH_CONF_DIR/auth.json"

# Log into Red Hat and Quay.io Container Registries
podman login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
podman login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io

# Build Container Image and save to Archive to be scanned
podman build --pull=true -t "${IMAGE}:${IMAGE_TAG}" $DOCKERFILE_LOCATION
podman save -o "${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" "${IMAGE}:${IMAGE_TAG}"

# Clean up / Remove Container Image
podman rmi "${IMAGE}:${IMAGE_TAG}"

# Install Specific Version of Syft - SBOM Generator
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b $TMP_JOB_DIR $SYFT_VERSION

# Install Specific Version of Grype - Vulnerability Scanner
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b $TMP_JOB_DIR $GRYPE_VERSION

# Download False Positives File from Platform Security GH Workflow Repo
curl -sSfL https://raw.githubusercontent.com/RedHatInsights/platform-security-gh-workflow/master/false_positives/grype-false-positives.yml \
    > ${TMP_JOB_DIR}/grype-false-positives.yml

# Create Artifacts Directory
mkdir -p $WORKSPACE/artifacts

# Scan Container Image with Syft
# Output SBOM in Text and JSON Format
$TMP_JOB_DIR/syft -v -o json "docker-archive:${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" \
    > $WORKSPACE/artifacts/sbom-results-${IMAGE}.json

$TMP_JOB_DIR/syft -v -o table "docker-archive:${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" \
    > $WORKSPACE/artifacts/sbom-results-${IMAGE}.txt

# Scan Container Image with Grype
# Output both "Full List" and "Only Fixable List" Vulnerabilities (text and json)
# Fail on detected defined level of Vulnerability Severity ("Only Fixable List")
$TMP_JOB_DIR/grype -v -o json "docker-archive:${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" \
    -c ${TMP_JOB_DIR}/grype-false-positives.yml \
    > $WORKSPACE/artifacts/vulnerability-results-full-${IMAGE}.json

$TMP_JOB_DIR/grype -v -o table "docker-archive:${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" \
    -c ${TMP_JOB_DIR}/grype-false-positives.yml \
    > $WORKSPACE/artifacts/vulnerability-results-full-${IMAGE}.txt

$TMP_JOB_DIR/grype -v -o json --only-fixed "docker-archive:${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" \
    -c ${TMP_JOB_DIR}/grype-false-positives.yml \
    > $WORKSPACE/artifacts/vulnerability-results-fixable-${IMAGE}.json

$TMP_JOB_DIR/grype -v -o table --only-fixed --fail-on $FAIL_ON_SEVERITY "docker-archive:${TMP_JOB_DIR}/${IMAGE_ARCHIVE}" \
    -c ${TMP_JOB_DIR}/grype-false-positives.yml \
    > $WORKSPACE/artifacts/vulnerability-results-fixable-${IMAGE}.txt

# Pass Jenkins dummy artifacts as it needs
# an xml output to consider the job a success.
cat << EOF > $WORKSPACE/artifacts/junit-dummy.xml
<testsuite tests="1">
    <testcase classname="dummy" name="dummytest"/>
</testsuite>
EOF
