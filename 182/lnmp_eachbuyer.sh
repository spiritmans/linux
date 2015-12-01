#!/bin/bash
# Author : sunbo@hofan.cn
# Usage	 : Install nginx+php+mysql

##############
yum -y install gcc* automake autoconf libtool make screen libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel openssl openssl-devel gd gd-devel ladp openldap openldap-devel  pcre-devel bison-devel

echo -e "PATH=\$PATH:/usr/local/cmake/bin:/usr/local/mysql/bin:/usr/local/nginx/sbin:/usr/local/php/sbin:/usr/local/php/bin\nexport PATH" >> /etc/profile
source /etc/profile

#pcre-8
cd /usr/local/src
wget http://jaist.dl.sourceforge.net/project/pcre/pcre/8.32/pcre-8.32.tar.gz
tar zxvf pcre-8.32.tar.gz
cd pcre-8.32
./configure --prefix=/usr/local/pcre
make && make install

#jemalloc
cd /usr/local/src/
wget http://www.canonware.com/download/jemalloc/jemalloc-3.6.0.tar.bz2
tar jxvf jemalloc-3.6.0.tar.bz2
cd jemalloc-3.6.0
./configure
make && make install
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig 

#nginx
useradd -s /sbin/nologin www
mkdir -p /app/www /app/shell /app/data /app/logs /app/www/backup
chown www:www /app/www -R
chmod 755 /app -R

cd /usr/local/src
wget http://tengine.taobao.org/download/tengine-2.1.0.tar.gz
tar zxvf tengine-2.1.0.tar.gz
cd tengine-2.1.0
sed -i 's/"Tengine"/"Eb Server"/' src/core/nginx.h
sed -i 's/"2.1.0"/"6.8.1"/' src/core/nginx.h
./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-pcre=/usr/local/src/pcre-8.32 --with-http_ssl_module --with-http_realip_module --with-http_gzip_static_module --with-jemalloc
make && make  install
echo "/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf" >> /etc/rc.local
mkdir /usr/local/nginx/conf/sites && mkdir /usr/local/nginx/conf/blockips
mv /usr/local/nginx/conf/nginx.conf   /usr/local/nginx/conf/nginx.conf_bak
cat >> /usr/local/nginx/conf/nginx.conf << EOF
user  www;
worker_processes  auto;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;


#pid        logs/nginx.pid;

events {
    use epoll;
    worker_connections  61200;
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    client_max_body_size 30m;

    log_format  main  '"$http_x_forwarded_for" $remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$request_time" "'
                      '"$upstream_response_time" "$http_user_agent" ';

    access_log  logs/access.log main;

    sendfile        on;
	server_tokens off;
    server_tag off;
    keepalive_timeout  65;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 128k;
    fastcgi_buffers 32 128k;

    gzip  on;
    gzip_min_length  1k;
    gzip_buffers     4 32k;
    gzip_http_version 1.1;
    gzip_comp_level 2;
    gzip_types       text/plain application/x-javascript text/css application/xml;
    gzip_vary on;

    server {
        listen 80 default;
        return 404;
	access_log off;
    }
    include sites/*.conf;
    include blockips/*.conf;
}
EOF

#mysql
cd /usr/local/src
groupadd mysql
useradd -M -s /sbin/nologin mysql -g mysql
mkdir -p /var/mysql/data
mkdir -p /var/mysql/log
wget http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.41.tar.gz
wget http://www.cmake.org/files/v2.8/cmake-2.8.12.2.tar.gz
wget http://ftp.gnu.org/gnu/bison/bison-3.0.tar.gz
tar zxvf cmake-2.8.12.2.tar.gz
cd cmake-2.8.12.2
./configure --prefix=/usr/local/cmake
make && make install
cd /usr/local/src
tar zxvf bison-3.0.tar.gz
cd bison-3.0
./configure --prefix=/usr/local/bison
make && make install
cd /usr/local/src
tar zxvf mysql-5.5.41.tar.gz
cd mysql-5.5.41
cmake . -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/mysql -DMYSQL_DATADIR:PATH=/var/mysql/data \
-DWITH_EXTRA_CHARSETS:STRING=utf8,gbk -DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DSYSCONFDIR=/var/mysql -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci -DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STOPAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 \
-DMYSQL_USER=mysql -DMYSQL_TCP_PORT=3306 -DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" -DWITH_SAFEMALLOC=OFF

make && make install
mv /etc/my.cnf /etc/my.cnf.old
cp support-files/my-medium.cnf /var/mysql/my.cnf
sed -i '/^ *#/d;/^$/d' /var/mysql/my.cnf
cp support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
chown -R mysql:mysql /usr/local/mysql/
chown -R mysql:mysql /var/mysql/
sh ./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/var/mysql/data

#启动mysql
service mysqld start
echo  "###############change mysql password################"
read -p "mysql password is:" passwd
/usr/local/mysql/bin/mysqladmin -u root password '$passwd'

#php
cd /usr/local/src
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar zxvf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local
make && make install
cd ..
wget http://jaist.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8/
./configure
make && make install
ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install
cd /usr/local/src
wget http://jaist.dl.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
tar zxvf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9
./configure
make && make install

ln -s /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
ln -s /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
ln -s /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
ln -s /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
ln -s /usr/local/lib/libmhash.a /usr/lib/libmhash.a
ln -s /usr/local/lib/libmhash.la /usr/lib/libmhash.la
ln -s /usr/local/lib/libmhash.so /usr/lib/libmhash.so
ln -s /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
ln -s /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
ln -s /usr/local/mysql/lib/libmysqlclient.so.18 /usr/lib64/
cp -frp /usr/lib64/libldap* /usr/lib/

cd /usr/local/src
wget http://jaist.dl.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
tar zxvf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8
ldconfig
./configure
make && make install

cd /usr/local/src
wget http://cn2.php.net/distributions/php-5.4.36.tar.gz
tar zxvf php-5.4.36.tar.gz
cd php-5.4.36
 ./configure  '--prefix=/usr/local/php' '--with-config-file-path=/usr/local/etc' '--with-pdo-mysql'   \
 '--with-mysql=/usr/local/mysql' '--with-mysqli=/usr/local/mysql/bin/mysql_config' '--with-iconv-dir=/usr/local'   \
 '--with-freetype-dir' '--with-jpeg-dir' '--with-png-dir' '--with-zlib' '--with-libxml-dir=/usr' '--enable-xml'   \
 '--disable-rpath' '--enable-bcmath' '--enable-shmop' '--enable-sysvsem' '--enable-inline-optimization'   \
 '--with-curl' '--with-curlwrappers' '--enable-mbregex' '--enable-fpm' '--enable-mbstring'   \
 '--with-mcrypt=/usr/local/libmcrytp/' '--with-gd' '--enable-gd-native-ttf' '--with-openssl' '--with-mhash'   \
 '--enable-pcntl' '--enable-sockets' '--with-ldap' '--with-ldap-sasl' '--with-xmlrpc' '--enable-zip' '--enable-soap'
make ZEND_EXTRA_LIBS='-liconv'
make install

cd /usr/local/src
mkdir /usr/local/php/logs
wget http://pecl.php.net/get/memcache-2.2.7.tgz
tar zxvf memcache-2.2.7.tgz
cd memcache-2.2.7
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

cd /usr/local/src/php-5.4.36
cp -f php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod u+x /etc/init.d/php-fpm 
chmod 755 /usr/local/php -R 
chkconfig php-fpm on

#添加tidy模块
yum -y install libtidy libtidy-devel
cd /usr/local/src/php-5.4.36/ext/tidy
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

#添加ftp模块
cd /usr/local/src/php-5.4.36/ext/ftp
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

#添加gettext模块
cd /usr/local/src/php-5.4.36/ext/gettext
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install

#修改php.ini
_path=`find /usr/local/php -name no-debug-non-zts*`/
sed -i "s#; extension_dir = \"./\"#extension_dir = \"$_path\"#g" /usr/local/php/etc/php.ini
sed -i 's/enable_dl = Off/enable_dl = On/g' /usr/local/php/etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16M/g' /usr/local/php/etc/php.ini
sed -i '/\[Tidy\]/a\extension=tidy.so' /usr/local/php/etc/php.ini
sed -i '/\[Date\]/a\date.timezone = Asia/Shanghai' /usr/local/php/etc/php.ini
cat >> /usr/local/php/etc/php.ini << EOF
[memcache]
extension=memcache.so
[ftp]
extension=ftp.so
[gettext]
extension=gettext.so
[pdo_mysql]
extension=pdo_mysql.so
EOF



echo "############安装完成，启动服务###################"
/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
service mysqld restart
/etc/init.d/php-fpm restart
echo "##############请修改/usr/local/php/etc/php-fpm.conf################"


