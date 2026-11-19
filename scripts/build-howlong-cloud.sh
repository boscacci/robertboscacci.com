#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."

[[ -z $(git status --porcelain) && $(git remote get-url origin) == git@github.com:boscacci/robertboscacci.com.git ]]
[[ $(aws sts get-caller-identity --query Account --output text) == 062008221187 ]]
commit=$(git rev-parse HEAD)
git merge-base --is-ancestor "$commit" refs/remotes/origin/main
[[ $(df -Pk . | awk 'NR==2 {print $4}') -ge 31457280 ]]
cache=$(docker system df --format '{{if eq .Type "Build Cache"}}{{.Reclaimable}}{{end}}' | awk 'NF {print $1}')
[[ $(numfmt --from=si "${cache%B}") -lt 10737418240 ]]

registry=062008221187.dkr.ecr.us-west-2.amazonaws.com
repo_name=robertboscacci-howlong
repo="$registry/$repo_name"
work=$(mktemp -d "${XDG_RUNTIME_DIR:?}/howlong-build.XXXXXXXX")
export DOCKER_CONFIG="$work/docker"
mkdir "$DOCKER_CONFIG"
builder="howlong-$(basename "$work" | tr '[:upper:]' '[:lower:]' | tr '.' '-')"
container="${builder}-smoke"
created_builder=false
created_container=false
added_local_image=false
cleanup() {
  if $created_container; then docker container rm -f "$container" >/dev/null || true; fi
  if $created_builder; then docker buildx rm "$builder" >/dev/null || true; fi
  if $added_local_image; then
    if [[ $(aws ecr describe-images --region us-west-2 --repository-name "$repo_name" --image-ids imageTag="$commit" --query 'imageDetails[0].imageDigest' --output text) == "$digest" ]]; then
      docker image rm "$repo@$digest" >/dev/null || true
    fi
  fi
  find "$work" -depth -delete
}
trap cleanup EXIT
npm run test:howlong
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "$registry" >/dev/null
digest=$(aws ecr describe-images --region us-west-2 --repository-name "$repo_name" --image-ids imageTag="$commit" \
  --query 'imageDetails[0].imageDigest' --output text 2>/dev/null || true)
if [[ -z $digest ]]; then
  docker buildx create --name "$builder" --driver docker-container >/dev/null
  created_builder=true
  git archive "$commit:services/howlong" | docker buildx build --builder "$builder" --platform linux/amd64 \
    --label "org.opencontainers.image.revision=$commit" --tag "$repo:$commit" --provenance=false --push -
  digest=$(aws ecr describe-images --region us-west-2 --repository-name "$repo_name" --image-ids imageTag="$commit" \
    --query 'imageDetails[0].imageDigest' --output text)
fi
[[ $digest =~ ^sha256:[a-f0-9]{64}$ ]]
aws ecr wait image-scan-complete --region us-west-2 --repository-name "$repo_name" --image-id imageDigest="$digest"
aws ecr describe-image-scan-findings --region us-west-2 --repository-name "$repo_name" --image-id imageDigest="$digest" \
  --query imageScanFindings.findingSeverityCounts --output json | jq -e '(.CRITICAL // 0) + (.HIGH // 0) == 0' >/dev/null

image="$repo@$digest"
if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker pull "$image" >/dev/null
  added_local_image=true
fi
docker run --rm --network none --read-only --cap-drop ALL --security-opt no-new-privileges:true --entrypoint aws "$image" --version
docker run -d --name "$container" --network none --read-only --cap-drop ALL --security-opt no-new-privileges:true \
  --tmpfs /state:uid=1000,gid=1000,mode=0700,size=8m --tmpfs /run/howlong:uid=1000,gid=1000,mode=0700,size=1m \
  -e HOWLONG_ORIGIN=https://smoke.invalid -e HOWLONG_OWNER=smoke@example.invalid \
  -e HOWLONG_STATE=/state/counter.sqlite -e HOWLONG_SOCKET=/run/howlong/server.sock \
  -e HOWLONG_INITIAL_DATE=2000-01-01 "$image" >/dev/null
created_container=true
for attempt in {1..10}; do
  if docker exec "$container" node /app/cloud-health.mjs; then break; fi
  if [[ $attempt == 10 ]]; then exit 1; fi
  sleep 1
done

state="${XDG_DATA_HOME:-$HOME/.local/share}/howlong/cloud"
mkdir -p "$state/releases"
record="$state/releases/$commit.json"
if [[ -f $record ]]; then
  jq -e --arg digest "$digest" --arg commit "$commit" '.commit == $commit and .digest == $digest' "$record" >/dev/null
else
  (set -o noclobber; jq -n --arg commit "$commit" --arg digest "$digest" --arg image "$image" \
    '{event:"howlong_cloud_image_verified",commit:$commit,digest:$digest,image:$image}' > "$record")
fi
cat "$record"
