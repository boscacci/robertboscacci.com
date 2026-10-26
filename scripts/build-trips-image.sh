#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
test -z "$(git status --porcelain)" || { echo 'Build requires a reviewed clean commit.' >&2; exit 1; }
commit="$(git rev-parse HEAD)"
repository=062008221187.dkr.ecr.us-west-2.amazonaws.com/robertboscacci-trips-private
test "$(aws sts get-caller-identity --query Account --output text)" = 062008221187
free_kib="$(df -Pk . | awk 'NR==2 {print $4}')"
test "$free_kib" -ge 31457280 || { echo 'Need at least 30 GiB free.' >&2; exit 1; }
builder="trips-${commit:0:12}"
task_docker_config="$(mktemp -d "${XDG_RUNTIME_DIR:-/dev/shm}/trips-docker.XXXXXX")"
export DOCKER_CONFIG="$task_docker_config"
cleanup() {
  docker buildx rm "$builder" >/dev/null 2>&1 || true
  rm -rf "$task_docker_config"
}
trap cleanup EXIT
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 062008221187.dkr.ecr.us-west-2.amazonaws.com >/dev/null
existing="$(aws ecr describe-images --repository-name robertboscacci-trips-private --region us-west-2 --image-ids imageTag="$commit" --query 'imageDetails[0].imageDigest' --output text 2>/dev/null || true)"
if test -z "$existing"; then
  docker buildx create --name "$builder" --driver docker-container >/dev/null
  docker buildx build --builder "$builder" --platform linux/amd64 --file services/trips/Dockerfile --tag "${repository}:${commit}" --push --provenance=false .
fi
digest="$(aws ecr describe-images --repository-name robertboscacci-trips-private --region us-west-2 --image-ids imageTag="$commit" --query 'imageDetails[0].imageDigest' --output text)"
mkdir -p outputs/private-trip
printf '%s@%s\n' "$repository" "$digest" > outputs/private-trip/private-image.txt
printf '{"event":"trips_image_published","commit":"%s","digest":"%s"}\n' "$commit" "$digest"
