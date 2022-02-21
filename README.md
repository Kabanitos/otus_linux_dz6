# Создание RPM-пакета
Для выполнения задания нам необходимо установить следующие пакеты :
```
redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc libtool perl-core openssl
```
Для автоиатизации установки добавим блок в Vagrantfile: 
```
  box.vm.provision "shell", inline: <<-SHELL
	      mkdir -p ~root/.ssh
              cp ~vagrant/.ssh/auth* ~root/.ssh
	      yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc libtool perl-core openssl
  	  SHELL
```
Для примера был выбран пакет NGINX,собирем его с поддрежкой openssl
Загружаем SRPM пакет NGINX длā далþнейшей работý над ним:
```
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
```
При установки пакета создаеться дерево каталогов для сборки:
```
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
```
Также нужно скачать и разархивировать последний исходники для openssl - он потребуется при сборке
```
wget https://www.openssl.org/source/openssl-1.1.1m.tar.gz --no-check-certificate
tar -xvf openssl-1.1.1m.tar.gz
```
Заранее установим зависимости, чтобы не было ошибок при сборке.
```
yum-builddep rpmbuild/SPECS/nginx.spec
```
Далее необходимо поправить spec файл, чтобы `nginx` собрался с необходимами нам опциями.
```
sed -i 's/--with-debug/--with-openssl=\/root\/openssl-1.1.1m/g' /root/rpmbuild/SPECS/nginx.spec
```
Приступаем к сборке пакета
```
rpmbuild -bb rpmbuild/SPECS/nginx.spec
```
Теперь можно установить наш пакет и убедится что  nginx работает

```
yum localinstall -y  rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
systemctl start nginx
systemctl enable nginx
systemctl status nginx
```
#Создание собсвенного репозитория 

Теперь приступим к созданию своего репозитория. Директория для статики у NGINX по умолчанию /usr/share/nginx/html. Создадим там каталог repo:
```
mkdir /usr/share/nginx/html/repo
```
Копируем туда наш собраный RPM пакет и добавим RPM для установки репозитория  Percona-Server
```
cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-9/redhat/percona-release-1.0-9.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-9.noarch.rpm
```
Инициализируем репозиторий командой
```
createrepo /usr/share/nginx/html/repo/
```
Настроим `NGINX` доступ к листингу каталога, для этого в location / в файле в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on и перещапускаем nginx 

```
sed -i '/index  index.html index.htm;/s/$/ \n\tautoindex on;/' /etc/nginx/conf.d/default.conf
nginx -s reload
```
Добавляем репозиторий в `/etc/yum.repos.d`
```
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```
Убедимся что репозиторий подключился и посмотрим что в нем есть:
```
yum repolist enabled | grep otus
yum list | grep otus
```

