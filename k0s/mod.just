set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

k0s_dir := justfile_directory() + '/k0s'
k0s_config := k0s_dir + '/cluster.yaml'

[private]
default:
    just -l k0s

[doc('Apply the k0sctl config to the cluster')]
apply:
    k0sctl apply --config "{{ k0s_config }}"

[doc('Generate kubeconfig')]
kubeconfig:
    OUTPUT=$(k0sctl kubeconfig --config "{{ k0s_config }}" 2>&1) && \
    echo "$OUTPUT" > "{{ justfile_directory() }}/kubeconfig" || \
    just log fatal "Failed to fetch kubeconfig" "stage" "$0"

[doc('Destroy the cluster')]
destroy:
    k0sctl reset --config "{{ k0s_config }}"
    rm "{{ justfile_directory() }}/kubeconfig"
