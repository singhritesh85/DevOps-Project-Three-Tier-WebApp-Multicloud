#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

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

while [ ! -e /dev/xvdb ]; do
    echo "Waiting for device /dev/xvdb to be attached..."
    sleep 5
done
echo "/dev/xvdb is ready!"
mkdir /mederma;
mkfs.xfs /dev/xvdb;
echo "/dev/xvdb  /mederma  xfs  defaults 0 0" >> /etc/fstab;
mount -a;

#################################### Installation of Rsyslog ###########################################

yum install rsyslog -y
systemctl start rsyslog
systemctl enable rsyslog
systemctl status rsyslog

################################################# Install RabbitMQ #############################################################

tee /etc/yum.repos.d/rabbitmq.repo <<EOF
[rabbitmq-erlang]
name=RabbitMQ Erlang Repository
baseurl=https://packagecloud.io/rabbitmq/erlang/el/9/\$basearch
enabled=1
gpgcheck=0
repo_gpgcheck=1
gpgkey=https://packagecloud.io/rabbitmq/erlang/gpgkey

[rabbitmq-server]
name=RabbitMQ Server Repository
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/\$basearch
enabled=1
gpgcheck=0
repo_gpgcheck=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
EOF

yum install erlang rabbitmq-server -y
systemctl start rabbitmq-server 
systemctl enable rabbitmq-server 
systemctl status rabbitmq-server
#rabbitmq-plugins list
#rabbitmq-plugins enable rabbitmq_management
#rabbitmqctl add_user test test
##rabbitmqctl set_user_tags test administrator
##rabbitmqctl set_permissions -p / test ".*" ".*" ".*"
#systemctl restart rabbitmq-server
#rabbitmq-plugins list
