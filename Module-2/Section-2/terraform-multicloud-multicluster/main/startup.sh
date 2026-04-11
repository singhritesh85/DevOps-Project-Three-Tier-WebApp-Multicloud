#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

#################################### Set Hostname for GCP VM Instance ##################################

hostnamectl set-hostname dexter-gcp-vm

##################################### create a user to login using SSH #################################

useradd -s /bin/bash -m dexter;
echo "Password@#795" | passwd dexter --stdin;
echo "Password@#795" | passwd root --stdin;
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config.d/50-cloud-init.conf
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/50-cloud-init.conf
systemctl reload sshd;
echo "dexter  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers

########################################################################################################

yum install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin vim zip unzip git wget rsyslog java-17*
systemctl enable rsyslog
systemctl start rsyslog
systemctl status rsyslog

while [ ! -e /dev/sdb ]; do
    echo "Waiting for device /dev/sdb to be attached..."
    sleep 5
done
echo "/dev/sdb is ready!"
mkdir /mederma;
mkfs.xfs /dev/sdb;
echo "/dev/sdb  /mederma  xfs  defaults 0 0" >> /etc/fstab;
mount -a;

############################################# Install Helm #############################################

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 --output /opt/get_helm.sh
chmod 700 /opt/get_helm.sh
/opt/get_helm.sh
#DESIRED_VERSION=v3.8.0 /opt/get_helm.sh

#reboot
helm version
kubectl version

############################################# Install Azure CLI ########################################

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo dnf install azure-cli -y

############################################# Install AWS CLI ##########################################

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

####################################################### Installation of GitLab Runner ###################################################################

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
yum install -y gitlab-runner
###gitlab-runner register            ### Run Manually
###systemctl start gitlab-runner     ### Run Manually
###systemctl enable gitlab-runner    ### Run Manually
###systemctl status gitlab-runner    ### Run Manually

#################################################### Required configuration and Packages ################################################################

yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io && systemctl start docker && systemctl enable docker
chown gitlab-runner:gitlab-runner /var/run/docker.sock
cd /opt/ && wget https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.9.12/apache-maven-3.9.12-bin.tar.gz
tar -xvf apache-maven-3.9.12-bin.tar.gz
mv /opt/apache-maven-3.9.12 /opt/apache-maven
cd /opt && wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
unzip sonar-scanner-cli-4.8.0.2856-linux.zip
rm -f sonar-scanner-cli-4.8.0.2856-linux.zip
mv /opt/sonar-scanner-4.8.0.2856-linux/ /opt/sonar-scanner
cd /opt && wget https://nodejs.org/dist/v16.0.0/node-v16.0.0-linux-x64.tar.gz
tar -xvf node-v16.0.0-linux-x64.tar.gz
rm -f node-v16.0.0-linux-x64.tar.gz
mv /opt/node-v16.0.0-linux-x64 /opt/node-v16.0.0
cd /opt && wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
unzip dependency-check-8.4.0-release.zip
rm -f dependency-check-8.4.0-release.zip
chown -R gitlab-runner:gitlab-runner /opt/dependency-check
cd /opt && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.68.2
echo 'JAVA_HOME="/usr/lib/jvm/java-17-openjdk-17.0.18.0.8-1.el8.x86_64"' >> /etc/profile
echo 'PATH="$PATH:$JAVA_HOME/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin:/opt/dependency-check/bin"' >> /etc/profile
echo "gitlab-runner  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers

##################################################### Installation Google-Cloud-Ops-Agent ###############################################################

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
systemctl status google-cloud-ops-agent
