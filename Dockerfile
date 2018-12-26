FROM centos:7
MAINTAINER Skiychan <dev@skiy.net>

ENV NGINX_VERSION 1.15.8
ENV PHP_VERSION 7.3.0

RUN set -x && \
    yum install -y gcc \
    gcc-c++ \
    autoconf \
    automake \
    libtool \
    make \
    cmake && \
#Install PHP library
## libmcrypt-devel DIY
    rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/a/argon2-20161029-2.el7.x86_64.rpm && \
    rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
    yum install -y zlib \
    zlib-devel \
    openssl \
    openssl-devel \
    pcre-devel \
    libxml2 \
    libxml2-devel \
    libcurl \
    libcurl-devel \
    libpng-devel \
    libjpeg-devel \
    freetype-devel \
    libicu-devel \
    libmcrypt-devel \
    openssh-server \
    wget \
    argon2 \
    # libargon2-0 \
    # libargon2-0-dev \
    python-setuptools && \
#Add user
    mkdir -p /data/{www,phpextini,phpextfile} && \
    useradd -r -s /sbin/nologin -d /data/www -m -k no www && \
#Download nginx & php
    mkdir -p /home/nginx-php && cd $_ && \
    curl -Lk http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
    curl -Lk http://php.net/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
#Make install nginx
    cd /home/nginx-php/nginx-$NGINX_VERSION && \
    ./configure --prefix=/usr/local/nginx \
    --user=www --group=www \
    --error-log-path=/var/log/nginx_error.log \
    --http-log-path=/var/log/nginx_access.log \
    --pid-path=/var/run/nginx.pid \
    --with-pcre \
    --with-http_ssl_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --with-http_gzip_static_module && \
    make && make install && \
#Add some extension for php
    mkdir -p /data/somefiles && cd $_ && \
#bison
    wget http://ftp.gnu.org/gnu/bison/bison-3.2.4.tar.gz && \
    tar -zxvf bison-3.2.4.tar.gz && cd bison-3.2.4/ && \
    ./configure && make && make install && \
#re2c
    wget https://github.com/skvadrik/re2c/releases/download/1.1.1/re2c-1.1.1.tar.gz && \
    tar -zxvf re2c-1.1.1.tar.gz && cd re2c-1.1.1/ && \
    ./configure && make && make install && \    
#libsodium
    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz  && \
    tar -zxvf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16/ && \
    ./configure && make && make install && \ 
#argon2   
#    wget https://github.com/P-H-C/phc-winner-argon2/archive/20171227.tar.gz && \
#    tar -zxvf 20171227.tar.gz && cd cd phc-winner-argon2-20171227/ && \
#    ./configure && make && make install && \ 
#remove somefiles    
    cd /data/ && rm -rf somefiles && \
#Make install php
    cd /home/nginx-php/php-$PHP_VERSION && \      
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/data/phpextini \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-iconv \
    --with-freetype-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --with-zlib \
    --with-libxml-dir=/usr \
    --with-curl \
    --with-password-argon2 \
    --with-sodium=/usr/local \
    --with-gd \
    --with-openssl \
    --with-mhash \   
    --with-xmlrpc \
    --with-xsl \
    --with-gettext \    
    --enable-mysqlnd \
    --enable-fileinfo \
    --enable-fpm \
    --enable-xml \
    --enable-bcmath \
    --enable-shmop \
    --enable-exif \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-pcntl \
    --enable-sockets \
    --enable-ftp \
    --enable-intl \
    --enable-zip \
    --enable-soap \
    --enable-opcache \
    --enable-ipv6 \    
    --disable-rpath \ 
    --disable-debug \       
    --without-libzip && \
    # --enable-session \
    # --without-pear && \
    make && make install && \
#Install php-fpm
    cd /home/nginx-php/php-$PHP_VERSION && \
    cp php.ini-production /usr/local/php/etc/php.ini && \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf && \
#Install supervisor
    easy_install supervisor && \
    mkdir -p /var/{log/supervisor,run/{sshd,supervisord}} && \
#Clean OS
    yum remove -y gcc \
    gcc-c++ \
    autoconf \
    automake \
    libtool \
    make \
    cmake && \
    yum clean all && \
    rm -rf /tmp/* /var/cache/{yum,ldconfig} /etc/my.cnf{,.d} && \
    mkdir -p --mode=0755 /var/cache/{yum,ldconfig} && \
    find /var/log -type f -delete && \
    rm -rf /home/nginx-php && \
#Change Mod from webdir
    chown -R www:www /data/www

#Add supervisord conf
ADD supervisord.conf /etc/

#Create web folder
# WEB Folder: /data/www
# SSL Folder: /usr/local/nginx/conf/ssl
# Vhost Folder: /usr/local/nginx/conf/vhost
# php extfile ini Folder: /usr/local/php/etc/conf.d
# php extfile Folder: /data/phpextfile
VOLUME ["/data/www", "/usr/local/nginx/conf/ssl", "/usr/local/nginx/conf/vhost", "/data/phpextini", "/data/phpextfile"]

ADD index.php /data/www/

#Add ext setting to image
#ADD extini/ /data/phpextini/
#ADD extfile/ /data/phpextfile/

#Update nginx config
ADD nginx.conf /usr/local/nginx/conf/

#Start
ADD start.sh /
RUN chmod +x /start.sh

#Set port
EXPOSE 80 443

#Start it
ENTRYPOINT ["/start.sh"]

#Start web server
#CMD ["/bin/bash", "/start.sh"]
