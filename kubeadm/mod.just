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
    gum spin --spinner dot --title "Transferring configuration..." -- \
        scp "{{ kubeadm_config }}" "{{ ssh_target }}:/tmp/kubeadm-config.yaml"
    just log info "Initializing cluster..."
    gum spin --spinner dot --title "Bootstrapping control plane (this may take a few minutes)..." -- \
        ssh "{{ ssh_target }}" 'sudo kubeadm init \
            --config /tmp/kubeadm-config.yaml \
            --upload-certs'
    just log info "$(just style success 'Cluster initialized successfully')"

[doc('Update kubeadm configuration')]
reconfigure:
    just log info "Copying updated config to server..."
    gum spin --spinner dot --title "Transferring configuration..." -- \
        scp "{{ kubeadm_config }}" "{{ ssh_target }}:/tmp/kubeadm-config.yaml"
    just log info "Uploading configuration to cluster ConfigMap..."
    gum spin --spinner dot --title "Updating ConfigMap..." -- \
        ssh "{{ ssh_target }}" 'sudo kubeadm init phase upload-config kubeadm --config /tmp/kubeadm-config.yaml'
    just log info "Applying configuration changes..."
    gum spin --spinner dot --title "Regenerating static pod manifests..." -- \
        ssh "{{ ssh_target }}" 'KUBE_VERSION=$(sudo kubectl --kubeconfig /etc/kubernetes/admin.conf version -o json | jq -r .serverVersion.gitVersion) && \
            sudo kubeadm upgrade apply $KUBE_VERSION --yes --config /home/brume/update.yaml'
    just log info "$(just style success 'Configuration applied. Control plane components will restart.')"

[doc('Fetch kubeconfig from server')]
kubeconfig:
    gum spin --spinner dot --title "Fetching kubeconfig..." -- \
        bash -c 'ssh "{{ ssh_target }}" "sudo cat /etc/kubernetes/admin.conf" > "{{ kubeconfig_path }}" && chmod 600 "{{ kubeconfig_path }}"'
    just log info "Kubeconfig saved to $(just style info '{{ kubeconfig_path }}')"

[doc('Destroy the cluster')]
destroy:
    if gum confirm "$(just style warning '⚠ Reset the cluster? This cannot be undone.')"; then \
        gum spin --spinner dot --title "Resetting cluster..." -- \
            ssh "{{ ssh_target }}" 'sudo kubeadm reset --force' && \
        rm -f "{{ kubeconfig_path }}" && \
        just log info "$(just style success 'Cluster destroyed')"; \
    else \
        just log info "Cancelled"; \
    fi

[doc('Upgrade cluster to specified version')]
upgrade version='':
    if [ -z "{{ version }}" ]; then \
        just log info "Fetching available versions..."; \
        ssh "{{ ssh_target }}" 'sudo kubeadm upgrade plan'; \
    else \
        if gum confirm "Upgrade to $(just style info '{{ version }}' --bold)?" --default="No"; then \
            just log info "Upgrading to version {{ version }}..."; \
            gum spin --spinner dot --title "Applying upgrade..." -- \
                ssh "{{ ssh_target }}" "sudo kubeadm upgrade apply {{ version }} --yes --config /home/brume/update.yaml" && \
            just log info "$(just style success 'Upgrade complete.')"; \
            just log info "$(just style warning 'Remember to upgrade kubelet/kubectl packages manually.')"; \
        else \
            just log info "Cancelled"; \
        fi; \
    fi

[doc('Show cluster version info')]
version:
    gum style --border rounded --padding "0 1" --margin "1 0" \
        "$(ssh {{ ssh_target }} 'sudo kubeadm version && kubectl version --client')"

[doc('Check cluster health')]
health:
    just style info 'Control Plane Status' --bold
    kubectl get nodes
    echo
    just style info 'System Pods' --bold
    kubectl get pods -n kube-system
