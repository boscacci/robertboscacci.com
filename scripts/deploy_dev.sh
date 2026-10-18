#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Only dev is supported. Running this script never triggers the main-branch workflow.
bucket=robertboscacci-com-dev-site
distribution=E282I2XU6PLMW4
base_url=https://dev.robertboscacci.com/
account=062008221187
hugo_bin=${HUGO_BIN:-hugo}
[[ -z $(git status --porcelain) ]] || { echo 'Commit or preserve pending changes before deploying.' >&2; exit 1; }
[[ $("$hugo_bin" version) == 'hugo v0.163.2-'* ]] || { echo 'Hugo 0.163.2 is required (set HUGO_BIN).' >&2; exit 1; }
[[ $(aws sts get-caller-identity --query Account --output text) == "$account" ]] || { echo 'Unexpected AWS account.' >&2; exit 1; }
[[ $(aws cloudfront get-distribution --id "$distribution" --query 'Distribution.DistributionConfig.Aliases.Items[0]' --output text) == dev.robertboscacci.com ]] || { echo 'Unexpected CloudFront alias.' >&2; exit 1; }
[[ $(aws cloudfront get-distribution --id "$distribution" --query 'Distribution.DistributionConfig.Origins.Items[0].DomainName' --output text) == "$bucket.s3.us-west-2.amazonaws.com" ]] || { echo 'Unexpected dev origin.' >&2; exit 1; }

commit=$(git rev-parse HEAD)
release="outputs/dev-releases/$commit"
mkdir -p "$release"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
event() { printf '{"event":"%s","commit":"%s","environment":"dev"}\n' "$1" "$commit"; }
trap 'event dev_deploy_failed >&2' ERR

if [[ ! -f "$release/site.tar.gz" ]]; then
  event dev_build_started
  "$hugo_bin" --gc --minify --environment development --baseURL "$base_url" --destination "$scratch/site"
  rm -f "$scratch/site/CNAME"
  printf '{"commit":"%s","environment":"dev"}\n' "$commit" > "$scratch/site/dev-release.json"
  tar -czf "$scratch/site.tar.gz" -C "$scratch/site" .
  mv "$scratch/site.tar.gz" "$release/site.tar.gz"
  (cd "$release" && sha256sum site.tar.gz > site.tar.gz.sha256)
else
  (cd "$release" && sha256sum --check site.tar.gz.sha256)
fi
mkdir -p "$scratch/deploy"
tar -xzf "$release/site.tar.gz" -C "$scratch/deploy"
SITE_DIRECTORY="$scratch/deploy" EXPECTED_COMMIT="$commit" npm test
event dev_upload_started
aws s3 sync "$scratch/deploy/" "s3://$bucket" --region us-west-2 --delete --cache-control 'public,max-age=300' --only-show-errors
invalidation=$(aws cloudfront create-invalidation --distribution-id "$distribution" --paths '/*' --query Invalidation.Id --output text)
event dev_cache_invalidation_started
aws cloudfront wait invalidation-completed --distribution-id "$distribution" --id "$invalidation"
SITE_BASE_URL="$base_url" EXPECTED_COMMIT="$commit" npm run smoke:dev
printf '{"commit":"%s","environment":"dev","invalidation":"%s","smoke":"passed"}\n' "$commit" "$invalidation" > "$release/deployment.json"
event dev_deploy_passed
