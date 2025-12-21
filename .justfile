#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

#mod bootstrap "bootstrap"
#mod kube "kubernetes"
#mod k0s "k0s"

[private]
default:
    just -l

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
    bws run --output env -- minijinja-cli "{{ file }}" {{ args }}
