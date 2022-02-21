#!/bin/bash
#Создаем свой RPM-пакет

cd /root
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
wget https://www.openssl.org/source/openssl-1.1.1m.tar.gz --no-check-certificate
adduser builder
usermod -aG builder root
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
tar -xvf openssl-1.1.1m.tar.gz
yum-builddep rpmbuild/SPECS/nginx.spec
sed -i 's/--with-debug/--with-openssl=\/root\/openssl-1.1.1m/g' /root/rpmbuild/SPECS/nginx.spec 
rpmbuild -bb rpmbuild/SPECS/nginx.spec
yum localinstall -y  rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
systemctl start nginx
systemctl enable nginx

#Создаем свой репозиторий

mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-9/redhat/percona-release-1.0-9.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm
createrepo /usr/share/nginx/html/repo/
sed -i '/index  index.html index.htm;/s/$/ \n\tautoindex on;/' /etc/nginx/conf.d/default.conf
nginx -s reload
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
