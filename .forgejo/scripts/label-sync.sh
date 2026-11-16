#!/usr/bin/env bash
set -euo pipefail

: "${FORGEJO_API_URL:?}" "${FORGEJO_REPOSITORY:?}"
config="${1:-.forgejo/labels.yaml}"
dry_run="${DRY_RUN:-false}"
base="${FORGEJO_API_URL}/repos/${FORGEJO_REPOSITORY}/labels"

auth=()
if [[ -n ${FORGEJO_TOKEN:-} ]]; then
  auth=(-H "Authorization: token ${FORGEJO_TOKEN}")
fi

api() {
  local method=$1 url=$2 body=${3:-}
  if [[ $method != GET && $dry_run == true ]]; then
    echo "dry-run: ${method} ${url} ${body}" >&2
    return 0
  fi
  local args=(-fsS -X "$method" "${auth[@]}" -H "Content-Type: application/json")
  if [[ -n $body ]]; then
    args+=(--data "$body")
  fi
  curl "${args[@]}" "$url"
}

existing='[]'
page=1
while :; do
  batch=$(api GET "${base}?limit=50&page=${page}")
  if [[ $(jq length <<<"$batch") -eq 0 ]]; then
    break
  fi
  existing=$(jq -c --argjson b "$batch" '. + $b' <<<"$existing")
  page=$((page + 1))
done

desired=$(yq -o=json '.' "$config")

jq -c -n --argjson existing "$existing" --argjson desired "$desired" '
  def norm: ascii_downcase | ltrimstr("#");
  ($existing | map({key: .name, value: .}) | from_entries) as $ex
  | [$desired[] | .name, (.aliases // [])[]] as $keep
  | (
      $desired[]
      | . as $d
      | ($d.description // "") as $desc
      | {name: $d.name, color: ("#" + ($d.color | norm)), description: $desc} as $body
      | ($ex[$d.name] // ([($d.aliases // [])[] | $ex[.] | select(. != null)] | first)) as $cur
      | if $cur == null then
          {op: "create", name: $d.name, body: $body}
        elif $cur.name != $d.name
          or ($cur.color | norm) != ($d.color | norm)
          or ($cur.description // "") != $desc then
          {op: "update", id: $cur.id, name: $d.name, from: $cur.name, body: $body}
        else empty end
    ),
    (
      $existing[]
      | select(.name | IN($keep[]) | not)
      | {op: "delete", id: .id, name: .name}
    )
' | while read -r action; do
  op=$(jq -r .op <<<"$action")
  name=$(jq -r .name <<<"$action")
  case $op in
    create)
      echo "create ${name}"
      api POST "$base" "$(jq -c .body <<<"$action")" >/dev/null
      ;;
    update)
      echo "update $(jq -r .from <<<"$action") -> ${name}"
      api PATCH "${base}/$(jq -r .id <<<"$action")" "$(jq -c .body <<<"$action")" >/dev/null
      ;;
    delete)
      echo "delete ${name}"
      api DELETE "${base}/$(jq -r .id <<<"$action")" >/dev/null
      ;;
  esac
done
