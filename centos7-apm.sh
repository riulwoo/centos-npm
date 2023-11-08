#!/usr/bin/bash

# 현재 파일, 경로 얻기
if [[ $1 -eq "" ]];then
    __FILE__=`realpath $0`
else
    __FILE__=`realpath $1`
fi
__DIR__=`dirname $__FILE__`

#centos의 selinux 끄기
sed -i 's/enforcing/disabled/' /etc/sysconfig/selinux
setenforce 0

# 기본 패키지 설치
yum update -y
yum install -y net-tools vim wget gzip git iputils-ping tar zip language-pack-ko chrony

#chrony 세팅
cat << EOF > /etc/chrony.conf
server time.bora.net iburst
server times.postech.ac.kr iburst
driftfile /var/lib/chrony/drift
rtcsync
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl enable chronyd

#센토스 php 설치 (7.2버전)
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y yum-utils
yum-config-manager --enable remi-php72
yum install -y php php-{fpm,zip,gd,mbstring,curl,xml,mysqlnd,cli}

#php-fpm 세팅
cat << EOF > /etc/php.ini
[PHP]
engine = On
short_open_tag = On
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 20M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 20M
max_file_uploads = 20
allow_url_fopen = Off
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
[filter]
[iconv]
[imap]
[intl]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
[Phar]
[mail function]
SMTP = localhost
smtp_port = 25
mail.add_x_header = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[OCI8]
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = SESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 0
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 1800
session.use_trans_sid = 0
session.sid_length = 26
session.trans_sid_tags = "a=href,area=href,frame=src,form="
session.sid_bits_per_character = 5
[Assertion]
zend.assertions = -1
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[dba]
[opcache]
[curl]
[openssl]
EOF


cat << EOF > /etc/php-fpm.conf
[global]
pid = /run/php7.2-fpm.pid
error_log = /var/log/php-fpm.log
include=/etc/php-fpm.d/*.conf
EOF

cat << EOF > /etc/php-fpm.d/www.conf

[www]
user = apache
group = apache
listen = /var/run/php-fpm/php-fpm.sock
listen.owner = apache
listen.group = apache
listen = 127.0.0.1:9000
listen.allowed_clients = 127.0.0.1
pm = dynamic
pm.max_children = 100
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF


# 센토스7 mariadb 10버전 설치
cat << EOF > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum install -y MariaDB-server MariaDB-client

#db 세팅
#config 값 수정
cat << EOF > /etc/my.cnf.d/config.cnf
[mysqld]

bind-address = 127.0.0.1

skip-external-locking
collation-server = utf8_general_ci
character-set-server = utf8
skip-character-set-client-handshake

# 리눅스 자체에 타임존 없어서 시간으로
# default-time-zone=Asia/Seoul
default-time-zone=+9:00

max-connections=1000
max-allowed-packet=4M
connect-timeout=5
wait-timeout=10
tcp-keepalive-time=10


[mysql]
default-character-set = utf8

[client]
default-character-set = utf8
EOF

systemctl enable mariadb
systemctl restart mariadb

#user 생성 및 권한 부여

mysql -e "create database mes";
mysql -e "create database mes_gara";
mysql -e "create user 'mes'@'localhost' identified by 'dkwnRhsid1\!'";
mysql -e "grant all privileges on mes.* to 'mes'@'localhost'";
mysql -e "grant all privileges on mes_gara.* to 'mes'@'localhost'";
mysql -e "flush privileges";

# 아파치 설치 및 세팅
yum install -y httpd
cat << EOF > /etc/httpd/conf/httpd.conf
ServerRoot "/etc/httpd"

Listen 80

Include conf.modules.d/*.conf

User apache
Group apache


ServerAdmin root@localhost
ServerName localhost:80

<Directory />
    AllowOverride none
    Require all denied
</Directory>

<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>

<VirtualHost *:80>
    DocumentRoot "/var/www/html"
    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ProxyRequests Off
    ProxyPreserveHost On
    ProxyErrorOverride on
    ProxyTimeout 5
    <FilesMatch \.(php)$>
        SetHandler "proxy:fcgi://localhost:9000"
    </FilesMatch>
</VirtualHost>


<IfModule dir_module>
    DirectoryIndex index.php index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>


<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types

    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType application/x-httpd-php .php .phtml .html .htm
    AddType application/x-httpd-php-source .phps

    AddHandler application/ etc.
    AddType text/html .html
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>


EnableSendfile on

IncludeOptional conf.d/*.conf


EOF

cat << EOF > /etc/httpd/conf/mes.conf
<VirtualHost *:80>
    # 깃으로 받은 프로젝트 폴더 경로로 수정
    DocumentRoot "/var/www/html"
    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ProxyRequests Off
    ProxyPreserveHost On
    ProxyErrorOverride on
    ProxyTimeout 5
    <FilesMatch \.(php)$>
        SetHandler "proxy:fcgi://localhost:9000"
    </FilesMatch>
</VirtualHost>

EOF


systemctl restart php-fpm
systemctl enable php-fpm.service

systemctl enable httpd
systemctl restart httpd


# 배포를 위한 웹 서버 세팅

# 편한 작업을 위한 sshd 세팅
# passwd 패스워드 변경
# /etc/ssh/sshd_config
# Port 변경
# PermitRootLogin yes
# PasswordAuthentication yes
# systemctl restart sshd

# 깃 클론해오기
# git clone {깃주소} /var/www/html

# 실사용 서버와 가라용 서버 나누기

# 권한 변경
# chown -R apache:apache /var/www/html

# db 구조 및 어드민 계정 넣기
# mysql db명 < 덤프파일.sql

# selinux disabled 적용을 위한 reboot
# reboot
