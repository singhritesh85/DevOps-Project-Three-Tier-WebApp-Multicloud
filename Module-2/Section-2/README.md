**Follow the below steps to create Istio Multicluster setup among Private EKS, Private GKE and Private AKS Clusters**
```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.28.3 sh -
```

Open the file and go to last line and edit it as written below
```
vim ~/.bashrc

PATH="$PATH:/home/k8s-management/istio-1.28.3/bin"
```

```
kubectl create ns istio-system --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
kubectl create ns istio-system --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev 
kubectl create ns istio-system --context=multicloud-aks-cluster
```
```
sudo yum groupinstall 'Development Tools' -y
```
```
mkdir certs 
cd certs/
make -f ../istio-1.28.3/tools/certs/Makefile.selfsigned.mk root-ca 
make -f ../istio-1.28.3/tools/certs/Makefile.selfsigned.mk multicloud-gke-cluster-cacerts 
make -f ../istio-1.28.3/tools/certs/Makefile.selfsigned.mk eks-demo-cluster-dev-cacerts
make -f ../istio-1.28.3/tools/certs/Makefile.selfsigned.mk multicloud-aks-cluster-cacerts
cd
```

=========================================================================================

```
kubectl create secret generic cacerts --from-file=certs/eks-demo-cluster-dev/ca-cert.pem --from-file=certs/eks-demo-cluster-dev/ca-key.pem --from-file=certs/eks-demo-cluster-dev/root-cert.pem --from-file=certs/eks-demo-cluster-dev/cert-chain.pem -n istio-system --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
kubectl get namespace istio-system && kubectl label namespace istio-system topology.istio.io/network=network1 --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-base istio/base -n istio-system --kube-context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
helm install istiod istio/istiod -n istio-system --set global.meshID=mesh1 --set meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="true" --set pilot.env.ENABLE_MULTICLUSTER_HEADLESS="true" --set pilot.env.PILOT_ENABLE_EDS_FOR_HEADLESS_SERVICES="true" --set global.multiCluster.clusterName=eks-demo-cluster-dev --set global.network=network1 --kube-context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
helm install istio-eastwestgateway istio/gateway -n istio-system --set name=istio-eastwestgateway --set networkGateway=network1 --set-string service.annotations."service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"="Internal" --kube-context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
kubectl get svc istio-eastwestgateway -n istio-system --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
```

```
kubectl create secret generic cacerts --from-file=certs/multicloud-gke-cluster/ca-cert.pem --from-file=certs/multicloud-gke-cluster/ca-key.pem --from-file=certs/multicloud-gke-cluster/root-cert.pem --from-file=certs/multicloud-gke-cluster/cert-chain.pem -n istio-system --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
kubectl get ns istio-system && kubectl label ns istio-system topology.istio.io/network=network2 --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-base istio/base -n istio-system --kube-context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
helm install istiod istio/istiod -n istio-system --set global.meshID=mesh1 --set meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="true" --set pilot.env.ENABLE_MULTICLUSTER_HEADLESS="true" --set pilot.env.PILOT_ENABLE_EDS_FOR_HEADLESS_SERVICES="true" --set global.multiCluster.clusterName=multicloud-gke-cluster --set global.network=network2 --kube-context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
helm install istio-eastwestgateway istio/gateway -n istio-system --set name=istio-eastwestgateway --set networkGateway=network2 --set-string "service.annotations.networking\\.gke\\.io/load-balancer-type"="Internal" --set service.type=LoadBalancer --kube-context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
kubectl get svc istio-eastwestgateway -n istio-system --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
```

```
kubectl create secret generic cacerts --from-file=certs/multicloud-aks-cluster/ca-cert.pem --from-file=certs/multicloud-aks-cluster/ca-key.pem --from-file=certs/multicloud-aks-cluster/root-cert.pem --from-file=certs/multicloud-aks-cluster/cert-chain.pem -n istio-system --context=multicloud-aks-cluster
kubectl get namespace istio-system && kubectl label namespace istio-system topology.istio.io/network=network3 --context=multicloud-aks-cluster
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-base istio/base -n istio-system --kube-context=multicloud-aks-cluster
helm install istiod istio/istiod -n istio-system --set global.meshID=mesh1 --set meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE="true" --set pilot.env.ENABLE_MULTICLUSTER_HEADLESS="true" --set pilot.env.PILOT_ENABLE_EDS_FOR_HEADLESS_SERVICES="true" --set global.multiCluster.clusterName=multicloud-aks-cluster --set global.network=network3 --kube-context=multicloud-aks-cluster
helm install istio-eastwestgateway istio/gateway -n istio-system --set name=istio-eastwestgateway --set networkGateway=network3 --set-string service.annotations."service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"="true" --kube-context=multicloud-aks-cluster
kubectl get svc istio-eastwestgateway -n istio-system --context=multicloud-aks-cluster
```
========================================================================================
```
cat expose-service.yaml

apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: cross-network-gateway
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        number: 15443
        name: tls
        protocol: TLS
      tls:
        mode: AUTO_PASSTHROUGH
      hosts:
        - "*.local"
```
```		
kubectl apply -f expose-service.yaml --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev	
kubectl apply -f expose-service.yaml --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
kubectl apply -f expose-service.yaml --context=multicloud-aks-cluster
```		
```
istioctl create-remote-secret --name=eks-demo-cluster-dev --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev | kubectl apply -f - --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
istioctl create-remote-secret --name=multicloud-gke-cluster --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster | kubectl apply -f - --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
istioctl create-remote-secret --name=eks-demo-cluster-dev --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev | kubectl apply -f - --context=multicloud-aks-cluster
istioctl create-remote-secret --name=multicloud-aks-cluster --context=multicloud-aks-cluster | kubectl apply -f - --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
istioctl create-remote-secret --name=multicloud-gke-cluster --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster | kubectl apply -f - --context=multicloud-aks-cluster
istioctl create-remote-secret --name=multicloud-aks-cluster --context=multicloud-aks-cluster | kubectl apply -f - --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
```
```
istioctl remote-clusters --context=arn:aws:eks:us-east-2:027330342406:cluster/eks-demo-cluster-dev
istioctl remote-clusters --context=gke_wise-trainer-244916_us-central1_multicloud-gke-cluster
istioctl remote-clusters --context=multicloud-aks-cluster
```
