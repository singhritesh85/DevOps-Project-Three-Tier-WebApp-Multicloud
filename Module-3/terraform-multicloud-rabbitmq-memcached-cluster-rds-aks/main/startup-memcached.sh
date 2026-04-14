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

yum install -y vim zip unzip git wget

while [ ! -e /dev/sdb ]; do
    echo "Waiting for device /dev/sdb to be attached..."
    sleep 5
done
echo "/dev/sdb is ready!"
mkdir /mederma;
mkfs.xfs /dev/sdb;
echo "/dev/sdb  /mederma  xfs  defaults 0 0" >> /etc/fstab;
mount -a;

################################################# Install Memcached #############################################################

yum install memcached libmemcached -y
systemctl start memcached
systemctl enable memcached
sed -i '0,/MAXCONN="1024"/s//MAXCONN="1500"/' /etc/sysconfig/memcached;
sed -i '0,/CACHESIZE="64"/s//CACHESIZE="256"/' /etc/sysconfig/memcached;
sed -i '0,/OPTIONS="-l 127.0.0.1,::1"/s//OPTIONS=""/' /etc/sysconfig/memcached;
systemctl restart memcached
