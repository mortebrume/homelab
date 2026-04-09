#!/usr/bin/env sh
set -eu

JSONNET_VERSION=0.20.0
JB_VERSION=0.6.0

echo "downloading jsonnet tooling"
mkdir -p /tmp/bin
wget -qO- "https://github.com/google/go-jsonnet/releases/download/v${JSONNET_VERSION}/go-jsonnet_${JSONNET_VERSION}_Linux_x86_64.tar.gz" | tar xz -C /tmp/bin jsonnet
wget -qO /tmp/bin/jb "https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v${JB_VERSION}/jb-linux-amd64"
chmod +x /tmp/bin/jb

export PATH="/tmp/bin:$PATH"

echo "cloning kubernetes-mixin"
cd /tmp
git clone --depth 1 https://github.com/kubernetes-monitoring/kubernetes-mixin.git
cd kubernetes-mixin

echo "installing jsonnet dependencies"
jb install

echo "rendering dashboards"
mkdir -p /data/dashboards
jsonnet -J vendor -m /data/dashboards lib/dashboards.jsonnet

echo "generating index"
cd /data/dashboards

dashboard_count=$(find . -maxdepth 1 -name "*.json" | wc -l)
updated=$(date -u +"%Y-%m-%d")

dashboards_html=""
for file in *.json; do
  if [ -f "$file" ]; then
    filename="${file%.json}"
    # Extract title from the Grafana dashboard JSON
    title=$(grep -o '"title": *"[^"]*"' "$file" | head -1 | sed 's/"title": *"//;s/"$//')
    if [ -z "$title" ]; then
      title="$filename"
    fi
    dashboards_html="${dashboards_html}<a href=\"${file}\" class=\"dashboard-card\"><div class=\"dashboard-title\">${title}</div><div class=\"dashboard-file\">${file}</div></a>"
  fi
done

cp /config/map/index.html index.html
sed -i "s|<!-- DASHBOARDS_PLACEHOLDER -->|${dashboards_html}|g" index.html
sed -i "s|DASHBOARD_COUNT_VALUE|${dashboard_count}|g" index.html
sed -i "s|LAST_UPDATED_VALUE|${updated}|g" index.html

echo "index created with ${dashboard_count} dashboards"
