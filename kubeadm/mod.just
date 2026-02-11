set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

kubeadm_dir := justfile_directory() + '/kubeadm'
kubeadm_config := kubeadm_dir + '/cluster.yaml'
ssh_target := 'brume@server'
kubeconfig_path := justfile_directory() + '/kubeconfig'

[private]
default:
    just -l kubeadm

[doc('Bootstrap the cluster with kubeadm')]
init:
    just log info "Copying kubeadm config to server..."
    scp "{{ kubeadm_config }}" "{{ ssh_target }}:/tmp/kubeadm-config.yaml"
    just log info "Initializing cluster..."
    ssh "{{ ssh_target }}" 'sudo kubeadm init \
        --config /tmp/kubeadm-config.yaml \
        --upload-certs'
    just log info "Cluster initialized successfully"

[doc('Fetch kubeconfig from server')]
kubeconfig:
    @ssh "{{ ssh_target }}" 'sudo cat /etc/kubernetes/admin.conf' > "{{ kubeconfig_path }}"
    @chmod 600 "{{ kubeconfig_path }}"
    just log info "Kubeconfig saved to {{ kubeconfig_path }}"

[doc('Destroy the cluster')]
destroy:
    gum confirm "Reset the cluster ?" --default="No" && \
        ssh "{{ ssh_target }}" 'sudo kubeadm reset --force'
    just log info "Cluster destroyed"

[doc('Upgrade cluster to specified version')]
upgrade version='':
    if [ -z "{{ version }}" ]; then \
        just log "Planning upgrade..."; \
        ssh "{{ ssh_target }}" 'sudo kubeadm upgrade plan'; \
    else; \
        just log "Upgrading to version {{ version }}..."; \
        ssh "{{ ssh_target }}" "sudo kubeadm upgrade apply {{ version }} --yes"; \
        just log "Upgrade complete."; \
    fi;

[doc('Show cluster version info')]
version:
    @ssh "{{ ssh_target }}" 'sudo kubeadm version && kubectl version --client'
