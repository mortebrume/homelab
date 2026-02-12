#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

mod bootstrap "bootstrap"
#mod kube "kubernetes"
mod kubeadm "kubeadm"

[private]
default:
    just -l

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
style type text *flags:
    #!/usr/bin/env bash
    case "{{ type }}" in
        success)
            gum style --foreground 2 {{ flags }} "{{ text }}"
            ;;
        warning)
            gum style --foreground 3 {{ flags }} "{{ text }}"
            ;;
        info)
            gum style --foreground 6 {{ flags }} "{{ text }}"
            ;;
        error)
            gum style --foreground 1 {{ flags }} "{{ text }}"
            ;;
        *)
            gum style {{ flags }} "{{ text }}"
            ;;
    esac

[private]
template file *args:
    minijinja-cli "{{ file }}" {{ args }} | op inject
