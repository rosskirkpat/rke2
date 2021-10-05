# ARG SERVERCORE_VERSION
# FROM mcr.microsoft.com/windows/servercore:${SERVERCORE_VERSION} AS build
# SHELL ["powershell", "-NoLogo", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
FROM mcr.microsoft.com/powershell:lts-nanoserver-1809-20210927 AS windows-runtime
ARG RUNTIME_PATH
ARG CRICTL_VERSION
ARG CONTAINERD_VERSION
ARG WINS_VERSION
ARG CALICO_VERSION
ARG CNI_PLUGIN_VERSION
ARG ARCH=amd64
ARG KUBERNETES_VERSION=dev

SHELL ["pwsh", "-NoLogo", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Write-Host "Using Kubernetes version:" $env:KUBERNETES_VERSION
RUN Write-Host "Using Runtime Path:" $env:RUNTIME_PATH

RUN New-Item -ItemType Directory -Path ${env:RUNTIME_PATH}
WORKDIR /tmp/

RUN curl.exe -sfL -R https://dl.k8s.io/release/$env:KUBERNETES_VERSION/bin/windows/amd64/kubectl.exe -o /rancher/kubectl.exe ; \ 
    curl.exe -sfL -R https://dl.k8s.io/release/$env:KUBERNETES_VERSION/bin/windows/amd64/kubelet.exe -o /rancher/kubelet.exe ; \
    curl.exe -sfL -R https://dl.k8s.io/release/$env:KUBERNETES_VERSION/bin/windows/amd64/kube-proxy.exe -o /rancher/kube-proxy.exe

RUN curl.exe -sfL -O -R https://github.com/containernetworking/plugins/releases/download/${env:CNI_PLUGIN_VERSION}/cni-plugins-windows-amd64-$env:CNI_PLUGIN_VERSION.tgz; \
    tar.exe xzvf cni-plugins-windows-amd64-$env:CNI_PLUGIN_VERSION.tgz --strip=1 win-overlay.exe host-local.exe ; \
    Move-Item -Path win-overlay.exe -Destination /rancher/win-overlay.exe  ; \
    Move-Item -Path host-local.exe -Destination /rancher/host-local.exe

RUN curl.exe -sfL -O -R https://github.com/containerd/containerd/releases/download/v${env:CONTAINERD_VERSION}/containerd-${env:CONTAINERD_VERSION}-windows-amd64.tar.gz; \ 
    tar xvzf containerd-${env:CONTAINERD_VERSION}-windows-amd64.tar.gz --strip=1 -C /rancher/

RUN curl.exe -sfL -O -R https://github.com/projectcalico/calico/releases/download/${env:CALICO_VERSION}/calico-windows-${env:CALICO_VERSION}.zip; \
    Expand-Archive -Path calico-windows-${env:CALICO_VERSION}.zip; \
    Move-Item -Path calico-windows-v3.19.2/CalicoWindows/calico-node.exe -Destination /rancher/calico-node.exe ; \
    Move-Item -Path calico-windows-v3.19.2/CalicoWindows/cni/calico.exe -Destination /rancher/calico.exe ; \
    Move-Item -Path calico-windows-v3.19.2/CalicoWindows/cni/calico-ipam.exe -Destination /rancher/calico-ipam.exe

# RUN curl.exe -sfL -O -R https://github.com/Microsoft/SDN/raw/master/Kubernetes/windows/hns.psm1

RUN curl.exe -sfL -O -R https://github.com/kubernetes-sigs/cri-tools/releases/download/${env:CRICTL_VERSION}/crictl-${env:CRICTL_VERSION}-windows-amd64.tar.gz ; \ 
    tar xzvf crictl-$env:CRICTL_VERSION-windows-amd64.tar.gz -C /rancher/

RUN curl.exe -sfL -R https://github.com/rancher/wins/releases/download/$env:WINS_VERSION/wins.exe -o /rancher/wins.exe

# RUN Move-Item -Path /rancher/*.exe /tmp/ -Force

# COPY /rancher/*.exe /bin/
# FROM prep AS windows-runtime
# WORKDIR /rancher/

FROM mcr.microsoft.com/windows/nanoserver:1809 AS windows-runtime-collect
COPY --from=windows-runtime /rancher/. /bin/

