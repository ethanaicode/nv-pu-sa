#!/usr/bin/env bash
# 刷新本地 archive.json 与 runtime-config.json：
# 1. 先从 nv-pu-sa.pages.dev 下载 runtime-config.json
# 2. 解析出其中的 r2_public_domain
# 3. 再从 {r2_public_domain}/data/archive.json 下载归档数据
set -euo pipefail

BASE_URL="https://nv-pu-sa.pages.dev"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

download_json() {
  local url="$1"
  local dest="$2"
  local tmp_file="$dest.tmp"
  echo "下载 $url -> $(basename "$dest") ..."
  if curl -fsSL "$url" -o "$tmp_file" && jq empty "$tmp_file" >/dev/null 2>&1; then
    mv "$tmp_file" "$dest"
    echo "✔ 已更新 $(basename "$dest")"
  else
    echo "✘ 下载或校验 $(basename "$dest") 失败（内容非合法 JSON）" >&2
    rm -f "$tmp_file"
    exit 1
  fi
}

download_json "$BASE_URL/runtime-config.json" "$DIR/runtime-config.json"

r2_public_domain="$(jq -r '.r2_public_domain' "$DIR/runtime-config.json")"
if [[ -z "$r2_public_domain" || "$r2_public_domain" == "null" ]]; then
  echo "✘ runtime-config.json 中未找到 r2_public_domain" >&2
  exit 1
fi

download_json "$r2_public_domain/data/archive.json" "$DIR/archive.json"

echo "全部文件刷新完成。"

