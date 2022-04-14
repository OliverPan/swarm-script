# ubuntu 20.04脚本
# change source list
mv /etc/apt/source.list /etc/apt/source.list.backup
cp ./soruce.list /etc/apt/
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install docker.io
cp ./daemon.json /etc/docker/
systemctl daemon-reload
systemctl restart docker

# Install K8S
apt-get install -y apt-transport-https curl
systemctl stop firewalld
swapoff -a
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add
apt-get update
sudo apt-get install kubelet=1.23.4-00 kubeadm=1.23.4-00 kubectl=1.23.4-00 -y
sudo docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.23.4
sudo docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.23.4
sudo docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.23.4
sudo docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.23.4
sudo docker pull registry.aliyuncs.com/google_containers/pause:3.6
sudo docker pull registry.aliyuncs.com/google_containers/etcd:3.5.1-0
sudo docker pull registry.aliyuncs.com/google_containers/coredns:v1.8.6
sudo docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.23.4 k8s.gcr.io/kube-apiserver:v1.23.4
sudo docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.23.4 k8s.gcr.io/kube-controller-manager:v1.23.4
sudo docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.23.4 k8s.gcr.io/kube-scheduler:v1.23.4
sudo docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.23.4 k8s.gcr.io/kube-proxy:v1.23.4
sudo docker tag registry.aliyuncs.com/google_containers/pause:3.6 k8s.gcr.io/pause:3.6
sudo docker tag registry.aliyuncs.com/google_containers/etcd:3.5.1-0 k8s.gcr.io/etcd:3.5.1-0
sudo docker tag registry.aliyuncs.com/google_containers/coredns:v1.8.6 k8s.gcr.io/coredns/coredns:v1.8.6



# install sgx driver
sudo apt-get install git -y
cd ~
sudo apt-get install linux-headers-$(uname -r) -y
sudo apt-get install dkms -y
git clone https://github.com/intel/SGXDataCenterAttestationPrimitives.git
cd ~/SGXDataCenterAttestationPrimitives/driver/linux
make
sudo cp ./ /usr/src/sgx-1.41/ -r -y
sudo dkms add -m sgx -v 1.41
sudo dkms build -m sgx -v 1.41
sudo dkms install -m sgx -v 1.41
sudo /sbin/modprobe intel_sgx
sudo cp  10-sgx.rules /etc/udev/rules.d
sudo groupadd sgx_prv
sudo udevadm trigger

# install MAGE sdk, intel sgx psw
sudo apt-get install build-essential ocaml ocamlbuild automake autoconf libtool wget python libssl-dev git cmake perl -y
sudo apt-get install libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev debhelper cmake reprepro unzip -y
cd ~
git clone https://github.com/Crepuscule-v/SGX_MAGE.git
cd  ~/SGX_MAGE
make preparation
sudo cp external/toolset/{current_distr}/* /usr/local/bin
make sdk
make sdk_install_pkg
sudo ./linux/installer/bin/sgx_linux_x64_sdk_2.15.101.1.bin --prefix /opt/intel/
source /opt/intel/sgxsdk/environment
make psw
make deb_psw_pkg
make deb_local_repo
sudo sh -c  "echo \"deb [trusted=yes arch=amd64] file:`pwd`/linux/installer/deb/sgx_debian_local_repo bionic main\" >> /etc/apt/sources.list"
sudo apt update
sudo apt-get install libsgx-launch libsgx-epid libsgx-quote-ex libsgx-urts libsgx-dcap-ql -y



# build or pull image
docker pull xmchen/node-feature-discovery:v0.10.1
docker tag xmchen/node-feature-discovery:v0.10.1 k8s.gcr.io/nfd/node-feature-discovery:v0.10.1
docker pull rancher/kube-rbac-proxy:v0.5.0
docker tag rancher/kube-rbac-proxy:v0.5.0 gcr.io/kubebuilder/kube-rbac-proxy:v0.5.0
docker build -t intel/sgx-sdk-demo:devel ./Dockerfile/sgx-sdk-demo/
docker build -t intel/sgx-aesmd-demo:devel ./Dockerfile/sgx-aesmd-demo/



# TODO
kubeadm join 172.16.137.33:6443 --token pm2pej.oif2ircwlb4ov6hg --discovery-token-ca-cert-hash sha256:f2fe5ecdb914216e5946b9e79888a286c9fda2a61e7f5211ea2bc452d30ec8ce