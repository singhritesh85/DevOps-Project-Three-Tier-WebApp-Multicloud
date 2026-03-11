#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;

#################################### Install Postgresql14 ##########################################

yum install -y postgresql15

cat > /opt/sonarqube.sql <<EODF
create database sonarqubedb;
create user ${SQ_USERNAME} with encrypted password ${SQ_PASSWORD};
grant all privileges on database sonarqubedb to ${SQ_USERNAME};
EODF

#################################### Installation of SonarQube Server ##############################################

useradd -s /bin/bash -m sonar;
echo "Password@#795" | passwd sonar --stdin;
echo "sonar  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers
sed -i '0,/PasswordAuthentication no/s//PasswordAuthentication yes/' /etc/ssh/sshd_config;
systemctl reload sshd;

cat >> /etc/sysctl.conf <<EOT
vm.max_map_count = 262144
fs.file-max = 65536
EOT

cat >> /etc/security/limits.conf <<EOF
sonar   -   nofile   65536

#Nofile is the maximum number of open files
EOF

sysctl -p
yum install -y java-17* rsyslog git
cd /opt/ && wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.5.90363.zip
unzip sonarqube-9.9.5.90363.zip
mv /opt/sonarqube-9.9.5.90363 /opt/sonarqube
chown -R sonar:sonar /opt/sonarqube

cat > /etc/systemd/system/sonarqube.service <<END_OF_SCRIPT
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
User=sonar
Group=sonar
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
END_OF_SCRIPT

systemctl enable sonarqube rsyslog
systemctl start sonarqube rsyslog
systemctl status sonarqube rsyslog

psql postgresql://${USERNAME}:${PASSWORD}@${RDS_ENDPOINT} -f /opt/sonarqube.sql
sed -i '/#sonar.jdbc.username=/s//sonar.jdbc.username=sonarqube/' /opt/sonarqube/conf/sonar.properties
sed -i '/#sonar.jdbc.password=/s//sonar.jdbc.password=Cloud#436/' /opt/sonarqube/conf/sonar.properties
sed -i 's%#sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube?currentSchema=my_schema%sonar.jdbc.url=jdbc:postgresql://${RDS_ENDPOINT}/sonarqubedb%g' /opt/sonarqube/conf/sonar.properties
systemctl restart sonarqube
