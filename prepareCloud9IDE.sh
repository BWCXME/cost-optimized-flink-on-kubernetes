if [ $# -eq 0 ]
  then
    echo "Please provide CloudformationStackName"
    return
fi

# 配置环境变量，方便后续操作
echo "config envs"
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
#export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
#export ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bashrc
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bashrc
aws configure set default.region ${AWS_REGION}
aws configure get default.region
aws configure set region $AWS_REGION

source ~/.bashrc
aws sts get-caller-identity

# 将CloudFormation的Output保存到环境变量，然后进一步记录到 `.bashrc`
export $(aws cloudformation describe-stacks --stack-name $1 --output text --query 'Stacks[0].Outputs[].join(`=`, [join(`_`, [`CF`, `OUT`, OutputKey]), OutputValue ])' --region $AWS_REGION)
echo "export EKS_VPC_ID=\"$CF_OUT_VpcId\"" >> ~/.bashrc
echo "export EKS_CONTROLPLANE_SG=\"$CF_OUT_ControlPlaneSecurityGroup\"" >> ~/.bashrc
echo "export EKS_SHAREDNODE_SG=\"$CF_OUT_SharedNodeSecurityGroup\"" >> ~/.bashrc
echo "export EKS_PUB_SUBNET_01=\"$CF_OUT_PublicSubnet1\"" >> ~/.bashrc
echo "export EKS_PUB_SUBNET_02=\"$CF_OUT_PublicSubnet2\"" >> ~/.bashrc
echo "export EKS_PUB_SUBNET_03=\"$CF_OUT_PublicSubnet3\"" >> ~/.bashrc
echo "export EKS_PRI_SUBNET_01=\"$CF_OUT_PrivateSubnet1\"" >> ~/.bashrc
echo "export EKS_PRI_SUBNET_02=\"$CF_OUT_PrivateSubnet2\"" >> ~/.bashrc
echo "export EKS_PRI_SUBNET_03=\"$CF_OUT_PrivateSubnet3\"" >> ~/.bashrc
echo "export EKS_KEY_ARN=\"$CF_OUT_EKSKeyArn\"" >> ~/.bashrc

source ~/.bashrc

# eksctl
echo "Install eksctl"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# 配置自动完成
cat >> ~/.bashrc <<EOF
. <(eksctl completion bash)
EOF
source ~/.bashrc


# 辅助工具
echo "Install jq, envsubst (from GNU gettext utilities) and bash-completion"
sudo yum -y install jq gettext bash-completion moreutils


# 更新 awscli 并配置自动完成
echo "Upgrade awscli to v2"
mv /bin/aws /bin/aws1
mv ~/anaconda3/bin/aws ~/anaconda3/bin/aws1
ls -l /usr/local/bin/aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
which aws_completer
echo $SHELL
cat >> ~/.bashrc <<EOF
complete -C '/usr/local/bin/aws_completer' aws
EOF
source ~/.bashrc
aws --version


# 安装 kubectl 并配置自动完成
echo "Install kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
cat >> ~/.bashrc <<EOF
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
EOF
source ~/.bashrc
kubectl version --client
# Enable some kubernetes aliases
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
sudo curl https://raw.githubusercontent.com/blendle/kns/master/bin/kns -o /usr/local/bin/kns && sudo chmod +x $_
sudo curl https://raw.githubusercontent.com/blendle/kns/master/bin/ktx -o /usr/local/bin/ktx && sudo chmod +x $_
# echo "alias kgn='kubectl get nodes -L beta.kubernetes.io/arch -L eks.amazonaws.com/capacityType -L beta.kubernetes.io/instance-type -L eks.amazonaws.com/nodegroup -L topology.kubernetes.io/zone -L karpenter.sh/provisioner-name -L karpenter.sh/capacity-type'" | tee -a ~/.bashrc
echo "alias kgn='kubectl get nodes -L beta.kubernetes.io/arch -L eks.amazonaws.com/capacityType -L beta.kubernetes.io/instance-type -L eks.amazonaws.com/nodegroup -L topology.kubernetes.io/zone'" | tee -a ~/.bashrc
echo "alias kgnk='kubectl get nodes -L beta.kubernetes.io/arch -L eks.amazonaws.com/capacityType -L beta.kubernetes.io/instance-type -L eks.amazonaws.com/nodegroup -L topology.kubernetes.io/zone -L karpenter.sh/provisioner-name -L karpenter.sh/capacity-type'" | tee -a ~/.bashrc
source ~/.bashrc



# 安装 helm
echo "Install helm"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version
helm repo add stable https://charts.helm.sh/stable



# 安装 awscurl 工具 https://github.com/okigan/awscurl
echo "Install awscurl"
cat >> ~/.bashrc <<EOF
export PATH=\$PATH:\$HOME/.local/bin:\$HOME/bin:/usr/local/bin
EOF
source ~/.bashrc

sudo python3 -m pip install awscurl


# 安装 session-manager 插件
echo "Install session-manager"
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"

sudo yum install -y session-manager-plugin.rpm

session-manager-plugin


# More tools
echo "Install yq for yaml processing"
echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc


echo "Install c9 to open files in cloud9"
npm install -g c9
# example  c9 open ~/package.json


echo "Install k9s a Kubernetes CLI To Manage Your Clusters In Style"
curl -sS https://webinstall.dev/k9s | bash
# 参考 https://segmentfault.com/a/1190000039755239



# 最后再执行一次 source
echo "source .bashrc"
shopt -s expand_aliases
source ~/.bashrc
