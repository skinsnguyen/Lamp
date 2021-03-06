#!/bin/bash

######################################################################
#           Auto Install & Optimize LEMP Stack on CentOS 7, 8        #
#                                                                    #
#                Author: Sanvv - HOSTVN Technical                    #
#                  Website: https://hostvn.vn                        #
#                                                                    #
#              Please do not remove copyright. Thank!                #
#  Please do not copy under any circumstance for commercial reason!  #
######################################################################

# shellcheck disable=SC2207

# Set Color
RED='\033[0;31m'
NC='\033[0m'

SCRIPTS_VERSION="1.0.5.5"

# Set variables
OS_VER=$(rpm -E %centos)
OS_ARCH=$(uname -m)
IPADDRESS=$(curl -s http://myip.directadmin.com)
DIR=$(pwd)
BASH_DIR="/var/hostvn"
PHP_MODULES_DIR="/usr/lib64/php/modules"
GITHUB_RAW_LINK="https://raw.githubusercontent.com"
EXT_LINK="https://scripts.hostvn.net"
UPDATE_LINK="https://scripts.hostvn.net/update"
GITHUB_URL="https://github.com"
PECL_PHP_LINK="https://pecl.php.net/get"
PMA_LINK="https://files.phpmyadmin.net/phpMyAdmin"
FILE_INFO="${BASH_DIR}/hostvn.conf"
HOSTNAME=$(hostname)
PHP2_RELEASE="no"
ADMIN_TOOL_PWD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c8)

# Copyright
AUTHOR="HOSTVN.VN"
AUTHOR_CONTACT="https://www.facebook.com/groups/hostvn.vn"

# Service Version
PHPMYADMIN_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "phpmyadmin_version=" | cut -f2 -d'=')
PHP_SYS_INFO_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "phpsysinfo_version=" | cut -f2 -d'=')
IGBINARY_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "igbinary_version=" | cut -f2 -d'=')
PHP_MEMCACHED_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "php_memcached_version=" | cut -f2 -d'=')
PHP_REDIS_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "php_redis_version=" | cut -f2 -d'=')
MARIADB_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "mariadb_version=" | cut -f2 -d'=')
#PHP_VERSION_1=$(curl -s ${UPDATE_LINK}/version | grep "php_version=" | cut -f2 -d'=')
#PHP_VERSION_2=$(curl -s ${UPDATE_LINK}/version | grep "php2_version=" | cut -f2 -d'=')
PHP_LIST=( $(curl -s "${UPDATE_LINK}"/version | grep "php_list=" | cut -f2 -d'=') )
if [[ "${OS_VER}" -eq 8 ]]; then
    index=0
    for keyword in "${PHP_LIST[@]}"; do
        if [[ "$keyword" = "php7.1" || "$keyword" = "php7.0" || "$keyword" = "php5.6" ]]; then
            unset "PHP_LIST[$index]"
        fi
        (( index++ ))
    done
fi

# Set Lang
OPTION_CHANGE_SSH="Ban co muon thay doi port SSH khong ? "
OPTION_INST_PUREFTP="Ban co muon cai dat PURE-FTPD (Quan ly FTP) khong ? "
OPTION_INST_AV="Ban co muon cai dat Clamav (Scan Malware) khong ? "
OPTION_INST_MEMCACHED="Ban co muon cai dat Memcached khong ? "
OPTION_INST_REDIS="Ban co muon cai dat Redis khong ? "
ENTER_OPTION="Nhap vao lua chon cua ban: "
SELECT_PHP="Hay lua chon phien ban PHP muon cai dat:"
WRONG_PHP_OPTION="Lua chon cua ban khong chinh xac, vui long chon lai."
SELECT_INST_PHP_2="Ban co muon cai dat phien ban PHP thu hai khong - Multiple PHP ?"
ENTER_OPTION_PHP_2="Nhap vao lua chon cua ban [1-2]: "
WRONG_PHP_SELECT_2="Ban nhap sai. Vui long nhap lai."
INVALID_PHP2_OPTION="${RED}Lua chon cua ban khong chinh xac. Vui long chon lai.${NC}"
SELECT_PHP_2="Lua chon phien ban PHP thu hai ban muon su dung:"
INST_MARIADB_ERR="Cai dat MariaDB that bai, vui long truy cap ${AUTHOR_CONTACT} de duoc ho tro."
INST_NGINX_ERR="Cai dat Nginx that bai, vui long truy cap ${AUTHOR_CONTACT} de duoc ho tro."
INST_PHP_ERR="Cai dat PHP that bai, vui long truy cap ${AUTHOR_CONTACT} de duoc ho tro."
INST_PHP_ERR_2="Cai dat PHP 2 that bai, vui long truy cap ${AUTHOR_CONTACT} de duoc ho tro"
INST_IGBINARY_ERR="Cai dat Igbinary that bai. Vui long cai dat lai: Igbinary, Php memcached ext, Phpredis."
INST_MEMEXT_ERR="Cai dat Php memcached extension khong thanh cong. Vui long cai dat lai."
INST_PHPREDIS_ERR="Cai dat  Phpredis khong thanh cong. Vui long cai dat lai."
INST_IGBINARY_ERR_2="Cai dat Igbinary cho PHP 2 khong thanh cong. Vui long cai dat lai: Igbinary, Php memcached ext, Phpredis."
INST_MEMEXT_ERR_2="Cai dat Php memcached extension cho PHP 2 khong thanh cong. Vui long cai dat lai."
INST_PHPREDIS_ERR_2="Cai dat Phpredis cho PHP 2 khong thanh cong. Vui long cai dat lai."
NGINX_NOT_WORKING="Nginx khong hoat dong."
MARIADB_NOT_WORKING="MariaDB khong hoat dong."
PUREFTP_NOT_WORKING="Pure-ftp khong hoat dong."
PHP_NOT_WORKING="PHP-FPM khong hoat dong."
LFD_NOT_WORKING="CSF khong hoat dong."
LFD_NOT_WORKING="LFD khong hoat dong."
LOGIN_NOTI1="Cam on ban da su dung dich vu cua ${AUTHOR}."
LOGIN_NOTI2="Neu can ho tro vui long truy cap ${AUTHOR_CONTACT}"
LOGIN_NOTI3="De mo menu ban go lenh sau:  hostvn"

# Random Port
RANDOM_ADMIN_PORT=$(shuf -i 49152-57343 -n 1)
CSF_UI_PORT=$(shuf -i 57344-65000 -n 1)

# Dir
DEFAULT_DIR_WEB="/usr/share/nginx/html"
DEFAULT_DIR_TOOL="/usr/share/nginx/private"
USR_DIR="/usr/share"

# Get info VPS
CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
RAM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
SWAP_TOTAL=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
PHP_MEM=${RAM_TOTAL}+${SWAP_TOTAL}
NGINX_PROCESSES=$(grep -c ^processor /proc/cpuinfo)
MAX_CLIENT=$((NGINX_PROCESSES * 1024))

rm -rf "${DIR}"/hostvn
rm -rf "${DIR}"/install

############################################
# Function
############################################
cd_dir(){
    cd "$1" || return
}

generate_random_pwd(){
    < /dev/urandom tr -dc A-Za-z0-9 | head -c16
}

valid_ip() {
    # shellcheck disable=SC2166
    if [ -n "$1" -a -z "${*##*\.*}" ]; then
    ipcalc "$1" | \
      awk 'BEGIN{FS=":";is_invalid=0} /^INVALID/ {is_invalid=1; print $1} END{exit is_invalid}'
  else
    return 1
  fi
}

############################################
# Prepare install
############################################
create_bash_dir(){
    mkdir -p /home/backup
    chmod 710 /home/backup
    chmod 711 /home
    mkdir -p "${BASH_DIR}"
}

# Config Selinux
config_selinux(){
    if [[ "${OS_VER}" -eq 8 ]]; then
        dnf -y install policycoreutils-python-utils
    fi

    se_status=$(getenforce)
    # if [ "${se_status}" == "Disabled" ]; then
    #     setenforce 0
    #     sed -i 's/SELINUX=disabled/SELINUX=permissive/g' /etc/selinux/config
    # fi
    # if [ "${se_status}" == "Enforcing" ]; then
    #     setenforce 0
    #     sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
    # fi
    if [ "${se_status}" == "Permissive" ]; then
        setenforce 0
        sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
    fi
    if [ "${se_status}" == "Enforcing" ]; then
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    fi
}

#Set timezone
set_timezone(){
    if [[ -f "/etc/localtime" && -f "/usr/share/zoneinfo/Asia/Ho_Chi_Minh" ]]; then
        rm -f /etc/localtime
        ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
    else
        timedatectl set-timezone Asia/Ho_Chi_Minh
    fi
}

#Set OS Archive
set_os_arch(){
    if [[ "${OS_ARCH}" == "x86_64" ]]; then
        OS_ARCH1="amd64"
    elif [[ "${OS_ARCH}" == "i686" ]]; then
        OS_ARCH1="x86"
    fi
}

# Admin Email
set_email(){
    clear
    while true
    do
        read -r -p "Nhap vao email cua ban: " ADMIN_EMAIL
        echo
        if [[ "${ADMIN_EMAIL}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]];
        then
            echo "Email cua ban la: ${ADMIN_EMAIL}."
            break
        else
            echo "Email ban nhap khong chinh xac vui long nhap lai."
        fi
    done
}

# Create log file
create_log(){
    LOG="/var/log/install.log"
    touch "${LOG}"
}

ssh_login_noti(){
    string=$(grep -rnw "/root/.bash_profile" -e "${AUTHOR}")
    if [ -z "${string}" ]; then
        {
            echo "echo \"${LOGIN_NOTI1}\""
            echo "echo \"${LOGIN_NOTI2}\""
            echo "echo \"${LOGIN_NOTI3}\""
        } >> ~/.bash_profile
    fi
}

############################################
# Option Install
############################################
input_ip(){
    echo "Nhap vao dia chi IP cua VPS. Bam Enter de script tu detect IP Public."
    read -r -p "Nhap vao dia chi IP cua VPS: " IPADDRESS_NEW
    if [ -n "${IPADDRESS_NEW}" ] && valid_ip "${IPADDRESS_NEW}" ; then
        IPADDRESS=${IPADDRESS_NEW}
    else
        printf "IP ban nhap khong chinh xac. Script se tu dong detect IP Public cua VPS."
    fi
}

select_php_ver(){
    clear
    while true
    do
        printf "%s\n" "${SELECT_PHP}"
        PS3="${ENTER_OPTION}"
        select opt in "${PHP_LIST[@]}"
        do
            case $opt in
                "$opt") PHP_VERSION="${opt/.}"; break;;
            esac
        done
        echo

        if [[ " ${PHP_LIST[*]} " == *" $(echo "${PHP_VERSION}" | fold -w4 | paste -sd'.') "* ]]; then
            break
        else
            clear
            printf "${RED}%s${NC}\n" "${WRONG_PHP_OPTION}"
        fi
    done
    sleep 1
}

select_php_multi(){
    clear
    printf "%s\n" "${SELECT_INST_PHP_2}"
    PS3="${ENTER_OPTION_PHP_2}"
    options=("Yes" "No")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes") MULTI_PHP="y"; break;;
            "No") MULTI_PHP="n"; break;;
            *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY";;
        esac
    done
    sleep 1
}

select_php_ver_2(){
    clear
    while true
    do
        printf "%s\n" "${SELECT_PHP_2}"
        PS3="${ENTER_OPTION}"
        select opt in "${PHP_LIST[@]}"
        do
            case $opt in
                "$opt") PHP_VERSION_2="${opt/.}"; break;;
            esac
        done
        echo

        if [[ " ${PHP_LIST[*]} " == *" $(echo "${PHP_VERSION_2}" | fold -w4 | paste -sd'.') "* ]]; then
            break
        else
            clear
            printf "${RED}%s\n${NC}" "${INVALID_PHP2_OPTION}"
        fi
    done
    sleep 1
}

option_clamav(){
    if [[ ${RAM_TOTAL} -gt 1049576 ]]; then
        clear
        printf "%s\n" "${OPTION_INST_AV}"
        PS3="${ENTER_OPTION}"
        options=("Yes" "No")
        select opt in "${options[@]}"
        do
            case $opt in
                "Yes") prompt_inst_av="y"; break;;
                "No") prompt_inst_av="n"; break;;
                *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY";;
            esac
        done
        sleep 1
    fi
}

option_memcached(){
    clear
    printf "%s\n" "${OPTION_INST_MEMCACHED}"
    PS3="${ENTER_OPTION}"
    options=("Yes" "No")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes") prompt_memcached="y"; break;;
            "No") prompt_memcached="n"; break;;
            *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY";;
        esac
    done
    sleep 1
}

option_redis(){
    clear
    printf "%s\n" "${OPTION_INST_REDIS}"
    PS3="${ENTER_OPTION}"
    options=("Yes" "No")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes") prompt_redis="y"; break;;
            "No") prompt_redis="n"; break;;
            *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY";;
        esac
    done
    sleep 1
}

option_pureftp(){
    clear
    printf "%s\n" "${OPTION_INST_PUREFTP}"
    PS3="${ENTER_OPTION}"
    options=("Yes" "No")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes") prompt_pureftpd="y"; break;;
            "No") prompt_pureftpd="n"; break;;
            *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY";;
        esac
    done
    sleep 1
}

option_change_ssh_port(){
    clear
    printf "%s\n" "${OPTION_CHANGE_SSH}"
    PS3="${ENTER_OPTION}"
    options=("Yes" "No")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes")
                prompt_ssh="y";
                SSH_PORT="8282";
                sleep 1
                printf "${RED}%s${NC}\n" "Port SSH moi l??: 8282";
                printf "${RED}%s${NC}\n" "Luu y: Voi Google Cloud cac ban can mo port 8282 trong tab VPC network";
                sleep 1
                break;;
            "No") prompt_ssh="n"; SSH_PORT="22" ; break;;
            *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY";;
        esac
    done
    sleep 1
}

############################################
# Install LEMP Stack
############################################

# Install Nginx
install_nginx(){
    if [[ -d /etc/nginx ]]; then
        rm -rf /etc/nginx
    fi
    cat >> "/etc/yum.repos.d/nginx.repo" << EONGINXREPO
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EONGINXREPO

    yum -y install yum-utils
    yum -y install nginx
    mkdir -p "${DEFAULT_DIR_TOOL}"
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"
    semanage permissive -a httpd_t
    systemctl start nginx
}

nginx_brotli(){
    NGINXV=$(nginx -v 2>&1 | grep -o '[0-9.]*$'; echo)
    MODULES_PATH="/etc/nginx/modules"
    wget -q "${EXT_LINK}"/ngx_brotli/"${NGINXV}"/ngx_http_brotli_filter_module.so -O  "${MODULES_PATH}"/ngx_http_brotli_filter_module.so
    wget -q "${EXT_LINK}"/ngx_brotli/"${NGINXV}"/ngx_http_brotli_static_module.so -O  "${MODULES_PATH}"/ngx_http_brotli_static_module.so

    if [[ -f "${MODULES_PATH}/ngx_http_brotli_filter_module.so" && -f "${MODULES_PATH}/ngx_http_brotli_static_module.so" ]]; then
        LOAD_BROTLI_FILTER="load_module modules/ngx_http_brotli_filter_module.so;"
        LOAD_BROTLI_STATIC="load_module modules/ngx_http_brotli_static_module.so;"
        INCLUDE_BROTLI="include /etc/nginx/extra/brotli.conf;"
        BROTLI_STATIC_OFF="brotli_static off;"
    fi
}

# Config naxsi
nginx_naxsi(){
    mkdir -p /etc/nginx/naxsi
    wget -q "${EXT_LINK}"/naxsi/"${NGINXV}"/ngx_http_naxsi_module.so -O  "${MODULES_PATH}"/ngx_http_naxsi_module.so
    wget -q "${EXT_LINK}"/naxsi/rule/naxsi_core.rules -O  /etc/nginx/naxsi/naxsi_core.rules
    wget -q "${EXT_LINK}"/naxsi/rule/wordpress.rules -O  /etc/nginx/naxsi/wordpress.rules
    wget -q "${EXT_LINK}"/naxsi/rule/drupal.rules -O  /etc/nginx/naxsi/drupal.rules
    wget -q "${EXT_LINK}"/naxsi/rule/naxsi_relax.rules -O  /etc/nginx/naxsi/naxsi_relax.rules

    if [[ -f "${MODULES_PATH}/ngx_http_naxsi_module.so" ]]; then
        LOAD_NAXSI="load_module modules/ngx_http_naxsi_module.so;"
    fi
}

create_naxsi_config(){
    cat >> "/etc/nginx/naxsi/disable_admin.conf" <<EOnaxsi_config
location /RequestDenied { internal; return 404; }
location /wp-admin {
    try_files \$uri \$uri/ /index.php?\$args;
    SecRulesDisabled;
}
location /admin {
    try_files \$uri \$uri/ /index.php?\$args;
    SecRulesDisabled;
}
location /admincp {
    try_files \$uri \$uri/ /index.php?\$args;
    SecRulesDisabled;
}
location /administrator {
    try_files \$uri \$uri/ /index.php?\$args;
    SecRulesDisabled;
}
EOnaxsi_config

    cat >> "/etc/nginx/naxsi/enable_naxsi.conf" <<EOenable_naxsi
## Naxsi rules
#LearningMode;
#SecRulesEnabled;
SecRulesDisabled;
DeniedUrl /RequestDenied;
## check rules
CheckRule "\$SQL >= 8" BLOCK;
CheckRule "\$RFI >= 8" BLOCK;
CheckRule "\$TRAVERSAL >= 4" BLOCK;
CheckRule "\$EVADE >= 4" BLOCK;
CheckRule "\$XSS >= 8" BLOCK;
# nginx-naxsi relaxation rules
include /etc/nginx/naxsi_config/naxsi_relax.rules;
include /etc/nginx/naxsi_config/wordpress.rules;
include /etc/nginx/naxsi_config/drupal.rules;
EOenable_naxsi
}

install_naxsi(){
    nginx_naxsi
    create_naxsi_config
}

#Install Mariadb
install_mariadb(){
    if [ -f "/etc/yum.repos.d/mariadb.repo" ]; then
        rm -rf /etc/yum.repos.d/mariadb.repo
    fi
    cat >> "/etc/yum.repos.d/mariadb.repo" << EOMARIADBREPO
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/${MARIADB_VERSION}/centos${OS_VER}-${OS_ARCH1}
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOMARIADBREPO
    if [[ "${OS_VER}" -eq 8 ]]; then
        dnf makecache
        dnf -y install galera-4
        #dnf install -y MariaDB-server MariaDB-client --disablerepo=AppStream
        dnf install -y mariadb-server
    else
        #yum -y install MariaDB-server MariaDB-client
        yum -y install mariadb-server
    fi

    /bin/systemctl start mariadb.service
}

# Install php-fpm
install_php(){
    if [ "${OS_VER}" -eq 8 ]; then
        PHP1_VERSION=${PHP_VERSION//php}
        PHP1_VERSION=$(echo "${PHP1_VERSION}" | fold -w1 | paste -sd'.')
        dnf module reset php -y
        dnf makecache
        dnf module enable php:remi-"${PHP1_VERSION}" -y
        yum install -y dnf-plugins-core
        dnf config-manager --set-enabled powertools
    else
        yum-config-manager --enable remi-"${PHP_VERSION}"
    fi

    yum -y install php php-fpm php-ldap php-zip php-embedded php-cli php-mysql php-common php-gd php-xml php-mbstring \
        php-mcrypt php-pdo php-soap php-json php-simplexml php-process php-curl php-bcmath php-snmp php-pspell php-gmp \
        php-intl php-imap php-enchant php-pear php-zlib php-xmlrpc php-devel \
        php-tidy php-opcache php-cli php-pecl-zip php-dom php-ssh2 php-xmlreader php-date php-exif php-filter php-ftp \
        php-hash php-iconv php-libxml php-pecl-imagick php-openssl php-pcre php-posix php-sockets php-spl \
        php-tokenizer php-bz2 php-pgsql php-sqlite3 php-fileinfo
}

install_php_2(){
    if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
        yum -y install "${PHP_VERSION_2}" "${PHP_VERSION_2}"-php-fpm "${PHP_VERSION_2}"-php-ldap "${PHP_VERSION_2}"-php-zip "${PHP_VERSION_2}"-php-embedded "${PHP_VERSION_2}"-php-cli "${PHP_VERSION_2}"-php-mysql "${PHP_VERSION_2}"-php-common "${PHP_VERSION_2}"-php-gd "${PHP_VERSION_2}"-php-xml "${PHP_VERSION_2}"-php-mbstring \
        "${PHP_VERSION_2}"-php-mcrypt "${PHP_VERSION_2}"-php-pdo "${PHP_VERSION_2}"-php-soap "${PHP_VERSION_2}"-php-json "${PHP_VERSION_2}"-php-simplexml "${PHP_VERSION_2}"-php-process "${PHP_VERSION_2}"-php-curl "${PHP_VERSION_2}"-php-bcmath "${PHP_VERSION_2}"-php-snmp "${PHP_VERSION_2}"-php-pspell "${PHP_VERSION_2}"-php-gmp \
        "${PHP_VERSION_2}"-php-intl "${PHP_VERSION_2}"-php-imap "${PHP_VERSION_2}"-php-enchant "${PHP_VERSION_2}"-php-pear "${PHP_VERSION_2}"-php-zlib "${PHP_VERSION_2}"-php-xmlrpc "${PHP_VERSION_2}"-php-devel \
        "${PHP_VERSION_2}"-php-tidy "${PHP_VERSION_2}"-php-opcache "${PHP_VERSION_2}"-php-cli "${PHP_VERSION_2}"-php-pecl-zip "${PHP_VERSION_2}"-php-dom "${PHP_VERSION_2}"-php-ssh2 "${PHP_VERSION_2}"-php-xmlreader "${PHP_VERSION_2}"-php-date "${PHP_VERSION_2}"-php-exif "${PHP_VERSION_2}"-php-filter "${PHP_VERSION_2}"-php-ftp \
        "${PHP_VERSION_2}"-php-hash "${PHP_VERSION_2}"-php-iconv "${PHP_VERSION_2}"-php-libxml "${PHP_VERSION_2}"-php-pecl-imagick "${PHP_VERSION_2}"-php-openssl "${PHP_VERSION_2}"-php-pcre "${PHP_VERSION_2}"-php-posix "${PHP_VERSION_2}"-php-sockets "${PHP_VERSION_2}"-php-spl \
        "${PHP_VERSION_2}"-php-tokenizer "${PHP_VERSION_2}"-php-bz2 "${PHP_VERSION_2}"-php-pgsql "${PHP_VERSION_2}"-php-sqlite3 "${PHP_VERSION_2}"-php-fileinfo

        PHP2_RELEASE="yes"
        PHP2_INI_PATH="/etc/opt/remi/${PHP_VERSION_2}/php.d"
        PHP_MODULES_DIR_2="/opt/remi/${PHP_VERSION_2}/root/usr/lib64/php/modules"

        if [[ ${PHP_VERSION_2} == "php56" ]]; then
            PHP2_INI_PATH="/opt/remi/${PHP_VERSION_2}/root/etc/php.d"
        fi
    fi
}

check_duplicate_php(){
    if [[ "${PHP_VERSION_2}" == "${PHP_VERSION}" ]]; then
        MULTI_PHP="n"
        echo "Phien ban PHP th??? 2 trung voi phien ban mac dinh. He thong se cai dat mot phien ban PHP."
    fi
}


############################################
# Install Composer
############################################
install_composer(){
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
}

############################################
# Install WP-CLI
############################################
install_wpcli(){
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
}

############################################
# Dynamic calculation
############################################
memory_calculation(){
    if [[ "${PHP_MEM}" -le '262144' ]]; then
        OPCACHE_MEM='128'
        MAX_MEMORY='128'
        PHP_REAL_PATH_LIMIT='512k'
        PHP_REAL_PATH_TTL='14400'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '262144' && "${PHP_MEM}" -le '393216' ]]; then
        OPCACHE_MEM='128'
        MAX_MEMORY='128'
        PHP_REAL_PATH_LIMIT='640k'
        PHP_REAL_PATH_TTL='21600'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '393216' && "${PHP_MEM}" -le '524288' ]]; then
        OPCACHE_MEM='128'
        MAX_MEMORY='128'
        PHP_REAL_PATH_LIMIT='768k'
        PHP_REAL_PATH_TTL='21600'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '524288' && "${PHP_MEM}" -le '1049576' ]]; then
        OPCACHE_MEM='144'
        MAX_MEMORY='160'
        PHP_REAL_PATH_LIMIT='768k'
        PHP_REAL_PATH_TTL='28800'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '1049576' && "${PHP_MEM}" -le '2097152' ]]; then
        OPCACHE_MEM='160'
        MAX_MEMORY='320'
        PHP_REAL_PATH_LIMIT='1536k'
        PHP_REAL_PATH_TTL='28800'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '2097152' && "${PHP_MEM}" -le '3145728' ]]; then
        OPCACHE_MEM='192'
        MAX_MEMORY='384'
        PHP_REAL_PATH_LIMIT='2048k'
        PHP_REAL_PATH_TTL='43200'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '3145728' && "${PHP_MEM}" -le '4194304' ]]; then
        OPCACHE_MEM='224'
        MAX_MEMORY='512'
        PHP_REAL_PATH_LIMIT='3072k'
        PHP_REAL_PATH_TTL='43200'
        MAX_INPUT_VARS="6000"
    elif [[ "${PHP_MEM}" -gt '4194304' && "${PHP_MEM}" -le '8180000' ]]; then
        OPCACHE_MEM='288'
        MAX_MEMORY='640'
        PHP_REAL_PATH_LIMIT='4096k'
        PHP_REAL_PATH_TTL='43200'
        MAX_INPUT_VARS="10000"
    elif [[ "${PHP_MEM}" -gt '8180000' && "${PHP_MEM}" -le '16360000' ]]; then
        OPCACHE_MEM='320'
        MAX_MEMORY='800'
        PHP_REAL_PATH_LIMIT='4096k'
        PHP_REAL_PATH_TTL='43200'
        MAX_INPUT_VARS="10000"
    elif [[ "${PHP_MEM}" -gt '16360000' && "${PHP_MEM}" -le '32400000' ]]; then
        OPCACHE_MEM='480'
        MAX_MEMORY='1024'
        PHP_REAL_PATH_LIMIT='4096k'
        PHP_REAL_PATH_TTL='43200'
        MAX_INPUT_VARS="10000"
    elif [[ "${PHP_MEM}" -gt '32400000' && "${PHP_MEM}" -le '64800000' ]]; then
        OPCACHE_MEM='600'
        MAX_MEMORY='1280'
        PHP_REAL_PATH_LIMIT='4096k'
        PHP_REAL_PATH_TTL='43200'
        MAX_INPUT_VARS="10000"
    elif [[ "${PHP_MEM}" -gt '64800000' ]]; then
        OPCACHE_MEM='800'
        MAX_MEMORY='2048'
        PHP_REAL_PATH_LIMIT='8192k'
        PHP_REAL_PATH_TTL='86400'
        MAX_INPUT_VARS="10000"
    fi
}

############################################
# Install Cache
############################################

# Install Memcached
install_memcached(){
    if [[ "${OS_VER}" -eq 8 ]]; then
        dnf -y install memcached
    else
        yum -y install memcached
    fi

    if [[ -f "/etc/sysconfig/memcached" ]]; then
        mv /etc/sysconfig/memcached /etc/sysconfig/memcached.bak
        cat >> "/etc/sysconfig/memcached" << EOMEMCACHED
PORT="11211"
USER="memcached"
MAXCONN="${MAX_CLIENT}"
CACHESIZE="${MAX_MEMORY}mb"
OPTIONS="-l 127.0.0.1 -U 0"
EOMEMCACHED
    fi
    semanage permissive -a memcached_t
}

# Install Redis
install_redis(){
    yum --enablerepo=remi install redis -y
    mv /etc/redis.conf /etc/redis.conf.bak
cat >> "/etc/redis.conf" << EOFREDIS
maxmemory ${MAX_MEMORY}mb
maxmemory-policy allkeys-lru
save ""
EOFREDIS
    semanage permissive -a redis_t
}

# Install igbinary
install_igbinary(){
    if [[ "${PHP_VERSION}" == "php56" ]]; then
        IGBINARY_VERSION="2.0.8"
    fi

    cd "${DIR}" && wget "${PECL_PHP_LINK}"/igbinary-"${IGBINARY_VERSION}".tgz
    tar -xvf igbinary-"${IGBINARY_VERSION}".tgz
    cd_dir "${DIR}/igbinary-${IGBINARY_VERSION}"
    /usr/bin/phpize && ./configure --with-php-config=/usr/bin/php-config
    make && make install
    cd "${DIR}" && rm -rf igbinary-"${IGBINARY_VERSION}" igbinary-"${IGBINARY_VERSION}".tgz

    if [[ -f "${PHP_MODULES_DIR}/igbinary.so" ]]; then
        cat >> "/etc/php.d/40-igbinary.ini" << EOF
extension=igbinary.so
EOF
    else
        echo "${INST_IGBINARY_ERR}" >> ${LOG}
    fi
}

install_igbinary_2(){
    if [[ "${PHP_VERSION_2}" == "php56" ]]; then
        IGBINARY_VERSION="2.0.8"
    fi

    cd "${DIR}" && wget "${PECL_PHP_LINK}"/igbinary-"${IGBINARY_VERSION}".tgz
    tar -xvf igbinary-"${IGBINARY_VERSION}".tgz
    cd_dir "${DIR}/igbinary-${IGBINARY_VERSION}"
    /opt/remi/"${PHP_VERSION_2}"/root/usr/bin/phpize && ./configure --with-php-config=/opt/remi/"${PHP_VERSION_2}"/root/usr/bin/php-config
    make && make install
    cd "${DIR}" && rm -rf igbinary-"${IGBINARY_VERSION}" igbinary-"${IGBINARY_VERSION}".tgz

    if [[ -f "${PHP_MODULES_DIR_2}/igbinary.so" ]]; then
        cat >> "${PHP2_INI_PATH}/40-igbinary.ini" << EOF
extension=igbinary.so
EOF
    else
        echo "${INST_IGBINARY_ERR_2}" >> ${LOG}
    fi
}

# Install Php memcached extension
install_php_memcached(){
    if [[ "${PHP_VERSION}" == "php56" ]]; then
        PHP_MEMCACHED_VERSION="2.2.0"
    fi

        cd "${DIR}" && wget "${PECL_PHP_LINK}"/memcached-"${PHP_MEMCACHED_VERSION}".tgz
        tar -xvf memcached-"${PHP_MEMCACHED_VERSION}".tgz
        cd_dir "${DIR}/memcached-${PHP_MEMCACHED_VERSION}"
        /usr/bin/phpize && ./configure --enable-memcached-igbinary --with-php-config=/usr/bin/php-config
        make && make install
        cd "${DIR}" && rm -rf memcached-"${PHP_MEMCACHED_VERSION}".tgz memcached-"${PHP_MEMCACHED_VERSION}"

    if [[ -f "${PHP_MODULES_DIR}/memcached.so" ]]; then
        cat >> "/etc/php.d/50-memcached.ini" << EOF
extension=memcached.so
EOF
    else
        echo "${INST_MEMEXT_ERR}" >> ${LOG}
    fi
}

install_php_memcached_2(){
    if [[ "${PHP_VERSION_2}" == "php56" ]]; then
        PHP_MEMCACHED_VERSION="2.2.0"
    fi

    cd "${DIR}" && wget "${PECL_PHP_LINK}"/memcached-"${PHP_MEMCACHED_VERSION}".tgz
        tar -xvf memcached-"${PHP_MEMCACHED_VERSION}".tgz
        cd_dir "${DIR}/memcached-${PHP_MEMCACHED_VERSION}"
        /opt/remi/"${PHP_VERSION_2}"/root/usr/bin/phpize && ./configure --enable-memcached-igbinary --with-php-config=/opt/remi/"${PHP_VERSION_2}"/root/usr/bin/php-config
        make && make install
        cd "${DIR}" && rm -rf memcached-"${PHP_MEMCACHED_VERSION}".tgz memcached-"${PHP_MEMCACHED_VERSION}"

    if [[ -f "${PHP_MODULES_DIR_2}/memcached.so" ]]; then
        cat >> "${PHP2_INI_PATH}/50-memcached.ini" << EOF
extension=memcached.so
EOF
    else
        echo "${INST_MEMEXT_ERR_2}" >> ${LOG}
    fi
}

# Install Phpredis
install_php_redis(){
    if [[ "${PHP_VERSION}" == "php56" ]]; then
        PHP_REDIS_VERSION="4.3.0"
    fi

    cd "${DIR}" && wget "${PECL_PHP_LINK}"/redis-"${PHP_REDIS_VERSION}".tgz
    tar -xvf redis-"${PHP_REDIS_VERSION}".tgz
    cd_dir "${DIR}/redis-${PHP_REDIS_VERSION}"
    /usr/bin/phpize && ./configure --enable-redis-igbinary --with-php-config=/usr/bin/php-config
    make && make install
    cd "${DIR}" && rm -rf redis-"${PHP_REDIS_VERSION}".tgz redis-"${PHP_REDIS_VERSION}"

    if [[ -f "${PHP_MODULES_DIR}/redis.so" ]]; then
        cat >> "/etc/php.d/50-redis.ini" << EOF
extension=redis.so
EOF
    else
        echo "${INST_PHPREDIS_ERR}" >> ${LOG}
    fi

}

install_php_redis_2(){
    if [[ "${PHP_VERSION_2}" == "php56" ]]; then
        PHP_REDIS_VERSION="4.3.0"
    fi

    cd "${DIR}" && wget "${PECL_PHP_LINK}"/redis-"${PHP_REDIS_VERSION}".tgz
    tar -xvf redis-"${PHP_REDIS_VERSION}".tgz
    cd_dir "${DIR}/redis-${PHP_REDIS_VERSION}"
    /opt/remi/"${PHP_VERSION_2}"/root/usr/bin/phpize && ./configure --enable-redis-igbinary --with-php-config=/opt/remi/"${PHP_VERSION_2}"/root/usr/bin/php-config
    make && make install
    cd "${DIR}" && rm -rf redis-"${PHP_REDIS_VERSION}".tgz redis-"${PHP_REDIS_VERSION}"

    if [[ -f "${PHP_MODULES_DIR_2}/redis.so" ]]; then
        cat >> "${PHP2_INI_PATH}/50-redis.ini" << EOF
extension=redis.so
EOF
    else
        echo "${INST_PHPREDIS_ERR_2}" >> "${LOG}"
    fi

}

############################################
# Config Nginx
############################################
# dynamic SSL cache size calculation
cal_ssl_cache_size(){
    if [[ ${RAM_TOTAL} -gt 500000 && ${RAM_TOTAL} -le 800000 ]]; then
        SSL_CACHE_SIZE=20
    elif [[ ${RAM_TOTAL} -gt 800000 && ${RAM_TOTAL} -le 1000000 ]]; then
        SSL_CACHE_SIZE=40
    elif [[ ${RAM_TOTAL} -gt 1000000 && ${RAM_TOTAL} -le 1880000 ]]; then
        SSL_CACHE_SIZE=60
    elif [[ ${RAM_TOTAL} -gt 1880000 && ${RAM_TOTAL} -le 2890000 ]]; then
        SSL_CACHE_SIZE=80
    elif [[ ${RAM_TOTAL} -gt 2890000 && ${RAM_TOTAL} -le 3890000 ]]; then
        SSL_CACHE_SIZE=150
    elif [[ ${RAM_TOTAL} -gt 3890000 && ${RAM_TOTAL} -le 7800000 ]]; then
        SSL_CACHE_SIZE=300
    elif [[ ${RAM_TOTAL} -gt 7800000 && ${RAM_TOTAL} -le 15600000 ]]; then
        SSL_CACHE_SIZE=500
    elif [[ ${RAM_TOTAL} -gt 15600000 && ${RAM_TOTAL} -le 23600000 ]]; then
        SSL_CACHE_SIZE=1000
    elif [[ ${RAM_TOTAL} -gt 23600000 ]]; then
        SSL_CACHE_SIZE=2000
    else
        SSL_CACHE_SIZE=10
    fi
}

self_signed_ssl(){
    #Create dhparams
    challenge_password=$(generate_random_pwd)
    self_signed_dir="/etc/nginx/ssl/server"
    mkdir -p "${self_signed_dir}"
    openssl dhparam -out /etc/nginx/ssl/dhparams.pem 2048
    openssl genrsa -out "${self_signed_dir}/server.key" 4096
    openssl req -new -days 3650 -key "${self_signed_dir}/server.key" -out "${self_signed_dir}/server.csr" <<EOF
VN
Cau Giay
Ha Noi
${AUTHOR}
IT
${IPADDRESS}
${ADMIN_EMAIL}
${challenge_password}
${AUTHOR}
EOF
    openssl x509 -in "${self_signed_dir}/server.csr" -out "${self_signed_dir}/server.crt" -req -signkey "${self_signed_dir}/server.key" -days 3650
}

create_nginx_conf(){
    mkdir -p /etc/nginx/backup_vhost
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

    cat >> "/etc/nginx/nginx.conf" << EONGINXCONF
user nginx;
worker_processes ${NGINX_PROCESSES};
worker_rlimit_nofile 260000;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

${LOAD_BROTLI_FILTER}
${LOAD_BROTLI_STATIC}
# ${LOAD_NAXSI}

events {
    worker_connections  ${MAX_CLIENT};
    accept_mutex off;
    accept_mutex_delay 200ms;
    use epoll;
    #multi_accept on;
}

http {
    index  index.html index.htm index.php;
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    charset utf-8;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                  '\$status \$body_bytes_sent "\$http_referer" '
                  '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  off;
    server_tokens off;

    sendfile on;

    tcp_nopush on;
    tcp_nodelay off;

    types_hash_max_size 2048;
    server_names_hash_bucket_size 128;
    server_names_hash_max_size 10240;
    client_max_body_size 1024m;
    client_body_buffer_size 128k;
    client_body_in_file_only off;
    client_body_timeout 60s;
    client_header_buffer_size 256k;
    client_header_timeout  20s;
    large_client_header_buffers 8 256k;
    keepalive_timeout 15;
    keepalive_disable msie6;
    reset_timedout_connection on;
    send_timeout 60s;

    disable_symlinks if_not_owner from=\$document_root;
    server_name_in_redirect off;

    open_file_cache max=2000 inactive=20s;
    open_file_cache_valid 120s;
    open_file_cache_min_uses 2;
    open_file_cache_errors off;

    # Limit Request
    limit_req_status 403;
    limit_conn_zone \$binary_remote_addr zone=one:10m;
    limit_req_zone \$binary_remote_addr zone=two:10m rate=1r/s;

    # Custom Response Headers
    add_header X-Powered-By ${AUTHOR};
    add_header X-Content-Type-Options    "nosniff" always;
    add_header X-XSS-Protection          "1; mode=block" always;
    add_header Referrer-Policy           "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Custom Variables
    map \$scheme \$https_suffix { default ''; https '-https'; }

    include /etc/nginx/extra/gzip.conf;
    ${INCLUDE_BROTLI}
    include /etc/nginx/extra/ssl.conf;
    include /etc/nginx/extra/cloudflare.conf;
    include /etc/nginx/web_apps.conf;
    include /etc/nginx/conf.d/*.conf;
}
EONGINXCONF
}

create_wp_cache_conf(){
    mkdir -p /etc/nginx/wordpress
    cat >> "/etc/nginx/wordpress/disable_xmlrpc.conf" << EOxmlrpc
# Disable XML-RPC
location = xmlrpc.php { deny all; access_log off; log_not_found off; }
EOxmlrpc

    cat >> "/etc/nginx/wordpress/disable_user_api.conf" << EOuser_api
#Block API User
location ~* /wp-json/wp/v2/users {
    allow 127.0.0.1;
    deny all;
    access_log off;
    log_not_found off;
}
EOuser_api

    cat >> "/etc/nginx/wordpress/wordpress_secure.conf" << EOwpsecure
include /etc/nginx/wordpress/disable_user_api.conf;
rewrite /wp-admin$ \$scheme://\$host\$uri/ permanent;

location /wp-includes/{
    location ~ \.(gz|tar|bzip2|7z|php|php5|php7|log|error|py|pl|kid|love|cgi)\$ {
        deny all;
    }
}
location /wp-content/uploads {
    location ~ \.(gz|tar|bzip2|7z|php|php5|php7|log|error|py|pl|kid|love|cgi)\$ {
        deny all;
    }
}
location /wp-content/updraft {
    deny all;
}
location /wp-content/uploads/sucuri {
    deny all;
}
location /wp-content/uploads/nginx-helper {
    deny all;
}
location = /wp-config.php {
    deny all;
}
location = /wp-links-opml.php {
    deny all;
}
location = /wp-config-sample.php {
    deny all;
}
location = /wp-comments-post.php {
    deny all;
}
location = /readme.html {
    deny all;
}
location = /license.txt {
    deny all;
}

# enable gzip on static assets - php files are forbidden
location /wp-content/cache {
# Cache css & js files
    location ~* \.(?:css(\.map)?|js(\.map)?|.html)\$ {
        add_header Access-Control-Allow-Origin *;
        access_log off;
        log_not_found off;
        expires 97d;
    }
    location ~ \.php\$ {
        #Prevent Direct Access Of PHP Files From Web Browsers
        deny all;
    }
}

EOwpsecure

    cat >> "/etc/nginx/wordpress/yoast_seo.conf" <<EOyoast_seo
#Yoast SEO Sitemaps
location ~* ^/wp-content/plugins/wordpress-seo(?:-premium)?/css/main-sitemap\.xsl\$ {}
location ~ ([^/]*)sitemap(.*).x(m|s)l\$ {
    ## this rewrites sitemap.xml to /sitemap_index.xml
    rewrite ^/sitemap.xml\$ /sitemap_index.xml permanent;
    ## this makes the XML sitemaps work
    rewrite ^/([a-z]+)?-?sitemap.xsl\$ /index.php?yoast-sitemap-xsl=\$1 last;
    rewrite ^/sitemap_index.xml\$ /index.php?sitemap=1 last;
    rewrite ^/([^/]+?)-sitemap([0-9]+)?.xml\$ /index.php?sitemap=\$1&sitemap_n=\$2 last;
    ## The following lines are optional for the premium extensions
    ## News SEO
    rewrite ^/news-sitemap.xml\$ /index.php?sitemap=wpseo_news last;
    ## Local SEO
    rewrite ^/locations.kml\$ /index.php?sitemap=wpseo_local_kml last;
    rewrite ^/geo-sitemap.xml\$ /index.php?sitemap=wpseo_local last;
    ## Video SEO
    rewrite ^/video-sitemap.xsl\$ /index.php?yoast-sitemap-xsl=video last;
}
EOyoast_seo

    cat >> "/etc/nginx/wordpress/rank_math_seo.conf" <<EOrank_math_seo
# RANK MATH SEO plugin
rewrite ^/sitemap_index.xml\$ /index.php?sitemap=1 last;
rewrite ^/([^/]+?)-sitemap([0-9]+)?.xml\$ /index.php?sitemap=\$1&sitemap_n=\$2 last;
EOrank_math_seo

    cat >> "/etc/nginx/wordpress/w3c.conf" << EOw3c
location ~ /wp-content/cache/minify/.*js_gzip\$ {
    gzip off;
    types {}
    default_type application/x-javascript;
    add_header Content-Encoding gzip;
    expires 31536000s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    add_header Vary "Accept-Encoding";
}
location ~ /wp-content/cache/minify/.*css_gzip\$ {
    gzip off;
    types {}
    default_type text/css;
    add_header Content-Encoding gzip;
    expires 31536000s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    add_header Vary "Accept-Encoding";
}
location ~ /wp-content/cache/page_enhanced.*gzip\$ {
    gzip off;
    types {}
    default_type text/html;
    add_header Content-Encoding gzip;
    expires 3600s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
}
location ~ \.(css|htc|less|js|js2|js3|js4)\$ {
    expires 31536000s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    try_files \$uri \$uri/ /index.php?\$args;
}
location ~ \.(html|htm|rtf|rtx|txt|xsd|xsl|xml)\$ {
    expires 3600s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    try_files \$uri \$uri/ /index.php?\$args;
}
location ~ \.(asf|asx|wax|wmv|wmx|avi|bmp|class|divx|doc|docx|exe|gif|gz|gzip|ico|jpg|jpeg|jpe|webp|json|mdb|mid|midi|mov|qt|mp3|m4a|mp4|m4v|mpeg|mpg|mpe|webm|mpp|_otf|odb|odc|odf|odg|odp|ods|odt|ogg|pdf|png|pot|pps|ppt|pptx|ra|ram|svg|svgz|swf|tar|tif|tiff|_ttf|wav|wma|wri|xla|xls|xlsx|xlt|xlw|zip)\$ {
    expires 31536000s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header Strict-Transport-Security "max-age=31536000";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    try_files \$uri \$uri/ /index.php?\$args;
}
set \$w3tc_enc "";
if (\$http_accept_encoding ~ gzip) { set \$w3tc_enc _gzip; }
if (-f \$request_filename\$w3tc_enc) { rewrite (.*) \$1\$w3tc_enc break; }
rewrite ^/wp-content/cache/minify/ /index.php last;
set \$w3tc_rewrite 1;
if (\$request_method = POST) { set \$w3tc_rewrite 0; }
if (\$query_string != "") { set \$w3tc_rewrite 0; }
if (\$request_uri !~ \/\$) { set \$w3tc_rewrite 0; }
if (\$http_cookie ~* "(comment_author|wp\-postpass|w3tc_logged_out|wordpress_logged_in|wptouch_switch_toggle)") {
    set \$w3tc_rewrite 0;
}
set \$w3tc_preview "";
if (\$http_cookie ~* "(w3tc_preview)") { set \$w3tc_preview _preview; }
set \$w3tc_ssl "";
if (\$scheme = https) { set \$w3tc_ssl _ssl; }
if (\$http_x_forwarded_proto = 'https') { set \$w3tc_ssl _ssl; }
set \$w3tc_enc "";
if (\$http_accept_encoding ~ gzip) { set \$w3tc_enc _gzip; }
if (!-f "\$document_root/wp-content/cache/page_enhanced/\$http_host/\$request_uri/_index\$w3tc_ssl\$w3tc_preview.html\$w3tc_enc") {
  set \$w3tc_rewrite 0;
}
if (\$w3tc_rewrite = 1) {
    rewrite .* "/wp-content/cache/page_enhanced/\$http_host/\$request_uri/_index\$w3tc_ssl\$w3tc_preview.html\$w3tc_enc" last;
}
EOw3c

    cat >> "/etc/nginx/wordpress/wpfc.conf" << EOwpfc
location / {
    error_page 418 = @cachemiss;
    error_page 419 = @mobileaccess;
    recursive_error_pages on;
    if (\$request_method = POST) { return 418; }
    if (\$arg_s != "") { return 418; }
    if (\$arg_p != "") { return 418; }
    if (\$args ~ "amp") { return 418; }
    if (\$arg_preview = "true") { return 418; }
    if (\$arg_ao_noptimize != "") { return 418; }
    if (\$http_cookie ~* "wordpress_logged_in_") { return 418; }
    if (\$http_cookie ~* "comment_author_") { return 418; }
    if (\$http_cookie ~* "wp_postpass_") { return 418; }
    if (\$http_user_agent = "Amazon CloudFront" ) { return 403; access_log off; }
    if (\$http_x_pull = "KeyCDN") { return 403; access_log off; }
    try_files "/wp-content/cache/all/\${uri}index.html" \$uri \$uri/ /index.php\$is_args\$args;
    add_header "X-Cache" "HIT";
    add_header "Vary" "Cookie";
}
location @mobileaccess {
    try_files "/wp-content/cache/wpfc-mobile-cache/\${uri}index.html" \$uri \$uri/ /index.php\$is_args\$args;
    add_header "X-Cache" "HIT";
    add_header "Vary" "User-Agent, Cookie";
    expires 30m;
    add_header "Cache-Control" "must-revalidate";
}
location @cachemiss {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
}

include /etc/nginx/extra/staticfiles.conf;
EOwpfc

    cat >> "/etc/nginx/wordpress/wpsc.conf" << EOwpsc
set \$cache_uri \$request_uri;
if (\$request_method = POST) { set \$cache_uri 'null cache'; }
if (\$query_string != "") { set \$cache_uri 'null cache'; }
if (\$request_uri ~* "(/wp-admin/|/xmlrpc.php|/wp-(app|cron|login|register|mail).php|wp-.*.php|/feed/|index.php|wp-comments-popup.php|wp-links-opml.php|wp-locations.php|sitemap(_index)?.xml|[a-z0-9_-]+-sitemap([0-9]+)?.xml)") {
    set \$cache_uri 'null cache';
}
if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_logged_in") {
    set \$cache_uri 'null cache';
}
location / {
    try_files /wp-content/cache/supercache/\$http_host/\$cache_uri/index.html \$uri \$uri/ /index.php ;
}
include /etc/nginx/extra/staticfiles.conf;
EOwpsc

    cat >> "/etc/nginx/wordpress/enabler.conf" << EOenabler
location / {
    error_page 418 = @cachemiss;
    error_page 419 = @mobileaccess;
    recursive_error_pages on;
    if (\$request_method = POST) { return 418; }
    if (\$arg_s != "") { return 418; }
    if (\$arg_p != "") { return 418; }
    if (\$args ~ "amp") { return 418; }
    if (\$arg_preview = "true") { return 418; }
    if (\$arg_ao_noptimize != "") { return 418; }
    if (\$http_cookie ~* "wordpress_logged_in_") { return 418; }
    if (\$http_cookie ~* "comment_author_") { return 418; }
    if (\$http_cookie ~* "wp_postpass_") { return 418; }
    try_files "/wp-content/cache/cache-enabler/\$host\${uri}index.html" \$uri \$uri/ /index.php\$is_args\$args;
    add_header "X-Cache" "HIT";
    expires 30m;
    add_header "Cache-Control" "must-revalidate";
}
location @mobileaccess {
    try_files "/wp-content/cache/supercache/\$host\${uri}index\$https_suffix-mobile.html" \$uri \$uri/ /index.php\$is_args\$args;
    add_header "X-Cache" "HIT";
    expires 30m;
    add_header "Cache-Control" "must-revalidate";
}

location @cachemiss {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
}

include /etc/nginx/extra/staticfiles.conf;
EOenabler

    cat >> "/etc/nginx/wordpress/swift2.conf" << EOswift2
set \$swift_cache 1;
if (\$request_method = POST){ set \$swift_cache 0; }
if (\$args != ''){ set \$swift_cache 0; }
if (\$http_cookie ~* "wordpress_logged_in") { set \$swift_cache 0; }
if (\$request_uri ~ ^/wp-content/cache/swift-performance/([^/]*)/assetproxy) {
    set \$swift_cache 0;
}

if (!-f "/wp-content/cache/swift-performance//\$http_host/\$request_uri/desktop/unauthenticated/index.html") {
    set \$swift_cache 0;
}

if (\$swift_cache = 1){
    rewrite .* /wp-content/cache/swift-performance//\$http_host/\$request_uri/desktop/unauthenticated/index.html last;
}

include /etc/nginx/extra/staticfiles.conf;
EOswift2

}

# Extra config
create_extra_conf(){
    # Include http block
    if [[ ! -d "/etc/nginx/extra" ]]; then
        mkdir -p /etc/nginx/extra
    fi

    cat >> "/etc/nginx/extra/brotli.conf" << EOFBRCONF
##Brotli Compression
brotli on;
brotli_static on;
brotli_buffers 16 8k;
brotli_comp_level 4;
brotli_types
    application/atom+xml
    application/geo+json
    application/javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rdf+xml
    application/rss+xml
    application/vnd.ms-fontobject
    application/wasm
    application/x-font-opentype
    application/x-font-truetype
    application/x-font-ttf
    application/x-javascript
    application/x-web-app-manifest+json
    application/xhtml+xml
    application/xml
    application/xml+rss
    font/eot
    font/opentype
    font/otf
    image/bmp
    image/svg+xml
    image/vnd.microsoft.icon
    image/x-icon
    image/x-win-bitmap
    text/cache-manifest
    text/calendar
    text/css
    text/javascript
    text/markdown
    text/plain
    text/vcard
    text/vnd.rim.location.xloc
    text/vtt
    text/x-component
    text/x-cross-domain-policy
    text/xml;
EOFBRCONF

    cat >> "/etc/nginx/extra/gzip.conf" << EOFGZCONF
##Gzip Compression
gzip on;
gzip_static on;
gzip_disable msie6;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 2;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_min_length 256;
gzip_types
    application/atom+xml
    application/geo+json
    application/javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rdf+xml
    application/rss+xml
    application/vnd.ms-fontobject
    application/wasm
    application/x-font-opentype
    application/x-font-truetype
    application/x-font-ttf
    application/x-javascript
    application/x-web-app-manifest+json
    application/xhtml+xml
    application/xml
    application/xml+rss
    font/eot
    font/opentype
    font/otf
    image/bmp
    image/svg+xml
    image/vnd.microsoft.icon
    image/x-icon
    image/x-win-bitmap
    text/cache-manifest
    text/calendar
    text/css
    text/javascript
    text/markdown
    text/plain
    text/vcard
    text/vnd.rim.location.xloc
    text/vtt
    text/x-component
    text/x-cross-domain-policy
    text/xml;
EOFGZCONF

    cat >> "/etc/nginx/extra/ssl.conf" << EOFSSLCONF
# SSL
ssl_session_timeout  1d;
ssl_session_cache    shared:SSL:${SSL_CACHE_SIZE}m;
ssl_session_tickets  off;

# Diffie-Hellman parameter for DHE ciphersuites
ssl_dhparam /etc/nginx/ssl/dhparams.pem;

# Mozilla Intermediate configuration
ssl_protocols        TLSv1.2 TLSv1.3;
ssl_ciphers          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

# OCSP Stapling
#ssl_stapling         on;
#ssl_stapling_verify  on;
resolver             1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 valid=10m;
resolver_timeout     10s;
EOFSSLCONF

    cat >> "/etc/nginx/extra/cloudflare.conf" << EOCF
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/12;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;
#set_real_ip_from 2400:cb00::/32;
#set_real_ip_from 2606:4700::/32;
#set_real_ip_from 2803:f800::/32;
#set_real_ip_from 2405:b500::/32;
#set_real_ip_from 2405:8100::/32;
#set_real_ip_from 2a06:98c0::/29;
#set_real_ip_from 2c0f:f248::/32;
real_ip_header X-Forwarded-For;
EOCF

cat >> "/etc/nginx/extra/nginx_limits.conf" << EOCF
fastcgi_connect_timeout 60;
fastcgi_buffer_size 128k;
fastcgi_buffers 256 16k;
fastcgi_busy_buffers_size 256k;
fastcgi_temp_file_write_size 256k;
fastcgi_send_timeout 600;
fastcgi_read_timeout 600;
fastcgi_intercept_errors on;
fastcgi_param HTTP_PROXY "";
EOCF

    # Include Server block
    cat >> "/etc/nginx/extra/staticfiles.conf" << EOSTATICFILES
location = /favicon.ico { allow all; log_not_found off; access_log off; }
location = /robots.txt { allow all; log_not_found off; access_log off; }
location ~* \.(gif|jpg|jpeg|png|ico|webp)\$ {
    gzip_static off;
    ${BROTLI_STATIC_OFF}
    add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 97d;
    break;
}
location ~* \.(3gp|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso)\$ {
    gzip_static off;
    ${BROTLI_STATIC_OFF}
    sendfile off;
    sendfile_max_chunk 1m;
    add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 97d;
    break;
}
location ~* \.(js)\$ {
    add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 97d;
    break;
}
location ~* \.(css)\$ {
    add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 97d;
    break;
}
location ~* \.(eot|svg|ttf|woff|woff2)\$ {
    add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    access_log off;
    expires 365d;
    break;
}
EOSTATICFILES

    cat >> "/etc/nginx/extra/security.conf" << EOsecurity
location ^~ /GponForm/ { deny all; access_log off; log_not_found off; }
location ^~ /GponForm/diag_Form { deny all; access_log off; log_not_found off; }
# Return 403 forbidden for readme.(txt|html) or license.(txt|html) or example.(txt|html) or other common git repository files
location ~*  "/(^\$|readme|license|example|LICENSE|README|LEGALNOTICE|INSTALLATION|CHANGELOG)\.(txt|html|md)" {
    deny all;
}
location ~ ^/(\.user.ini|\.htaccess|\.htpasswd|\.user\.ini|\.ht|\.env|\.git|\.svn|\.project) {
    deny all;
    access_log off;
    log_not_found off;
}
# Deny backup extensions & log files and return 403 forbidden
location ~* "\.(love|error|kid|cgi|old|orig|original|php#|php~|php_bak|save|swo|aspx?|tpl|sh|bash|bak?|cfg|cgi|dll|exe|git|hg|ini|jsp|log|mdb|out|sql|svn|swp|tar|rdf|gz|zip|bz2|7z|pem|asc|conf|dump)\$" {
    deny all;
}

# block base64_encoded content
location ~* "(base64_encode)(.*)(\()" { deny all; }
# block javascript eval()
location ~* "(eval\()" { deny all; }
# Additional security settings
location ~* "(127\.0\.0\.1)" { deny all; }
location ~* "([a-z0-9]{2000})" { deny all; }
location ~* "(javascript\:)(.*)(\;)" { deny all; }
location ~* "(GLOBALS|REQUEST)(=|\[|%)" { deny all; }
location ~* "(<|%3C).*script.*(>|%3)" { deny all; }
location ~* "(boot\.ini|etc/passwd|self/environ)" { deny all; }
location ~* "(thumbs?(_editor|open)?|tim(thumb)?)\.php" { deny all; }
location ~* "(https?|ftp|php):/" { deny all; }
EOsecurity
}

vhost_custom(){
    REWRITE_CONFIG_PATH="/etc/nginx/rewrite"
    mkdir -p "${REWRITE_CONFIG_PATH}"
cat >> "${REWRITE_CONFIG_PATH}/default.conf" << EOrewrite_default
location / {
    try_files \$uri \$uri/ /index.php?\$query_string;
}
EOrewrite_default

cat >> "${REWRITE_CONFIG_PATH}/codeigniter.conf" << EOrewrite_ci
location / {
    try_files \$uri \$uri/ /index.php?/\$request_uri;
}
EOrewrite_ci

cat >> "${REWRITE_CONFIG_PATH}/discuz.conf" << EOrewrite_discuz
location / {
    rewrite ^([^\.]*)/topic-(.+)\.html\$ \$1/portal.php?mod=topic&topic=\$2 last;
    rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html\$ \$1/portal.php?mod=view&aid=\$2&page=\$3 last;
    rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html\$ \$1/forum.php?mod=forumdisplay&fid=\$2&page=\$3 last;
    rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html\$ \$1/forum.php?mod=viewthread&tid=\$2&extra=page%3D\$4&page=\$3 last;
    rewrite ^([^\.]*)/group-([0-9]+)-([0-9]+)\.html\$ \$1/forum.php?mod=group&fid=\$2&page=\$3 last;
    rewrite ^([^\.]*)/space-(username|uid)-(.+)\.html\$ \$1/home.php?mod=space&\$2=\$3 last;
    rewrite ^([^\.]*)/blog-([0-9]+)-([0-9]+)\.html\$ \$1/home.php?mod=space&uid=\$2&do=blog&id=\$3 last;
    rewrite ^([^\.]*)/(fid|tid)-([0-9]+)\.html\$ \$1/index.php?action=\$2&value=\$3 last;
    rewrite ^([^\.]*)/([a-z]+[a-z0-9_]*)-([a-z0-9_\-]+)\.html\$ \$1/plugin.php?id=\$2:\$3 last;
}
EOrewrite_discuz

cat >> "${REWRITE_CONFIG_PATH}/drupal.conf" << EOrewrite_drupal
location / {
    try_files \$uri /index.php?\$query_string;
}
location ~ \..*/.*\.php\$ { return 403; }
location ~ ^/sites/.*/private/ { return 403; }
# Block access to scripts in site files directory
location ~ ^/sites/[^/]+/files/.*\.php\$ { deny all; }
location ~ (^|/)\. { return 403; }
location ~ /vendor/.*\.php\$ { deny all; return 404; }
location @rewrite {
    rewrite ^/(.*)\$ /index.php?q=\$1;
}
location ~* \.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?\$|composer\.(lock|json)\$|web\.config\$|^(\.(?!well-known).*|Entries.*|Repository|Root|Tag|Template)\$|^#.*#\$|\.php(~|\.sw[op]|\.bak|\.orig|\.save)\$ {
    deny all;
    return 404;
}
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)\$ {
    try_files \$uri @rewrite;
    expires max;
    log_not_found off;
}
location ~ ^/sites/.*/files/styles/ { # For Drupal >= 7
    try_files \$uri @rewrite;
}
location ~ ^(/[a-z\-]+)?/system/files/ { # For Drupal >= 7
    try_files \$uri /index.php?\$query_string;
}
if (\$request_uri ~* "^(.*/)index\.php/(.*)") {
    return 307 \$1\$2;
}
EOrewrite_drupal

cat >> "${REWRITE_CONFIG_PATH}/ecshop.conf" << EOrewrite_ecshop
if (!-e \$request_filename) {
    rewrite "^/index\.html" /index.php last;
    rewrite "^/category\$" /index.php last;
    rewrite "^/feed-c([0-9]+)\.xml\$" /feed.php?cat=\$1 last;
    rewrite "^/feed-b([0-9]+)\.xml\$" /feed.php?brand=\$1 last;
    rewrite "^/feed\.xml\$" /feed.php last;
    rewrite "^/category-([0-9]+)-b([0-9]+)-min([0-9]+)-max([0-9]+)-attr([^-]*)-([0-9]+)-(.+)-([a-zA-Z]+)(.*)\.html\$" /category.php?id=\$1&brand=\$2&price_min=\$3&price_max=\$4&filter_attr=\$5&page=\$6&sort=\$7&order=\$8 last;
    rewrite "^/category-([0-9]+)-b([0-9]+)-min([0-9]+)-max([0-9]+)-attr([^-]*)(.*)\.html\$" /category.php?id=\$1&brand=\$2&price_min=\$3&price_max=\$4&filter_attr=\$5 last;
    rewrite "^/category-([0-9]+)-b([0-9]+)-([0-9]+)-(.+)-([a-zA-Z]+)(.*)\.html\$" /category.php?id=\$1&brand=\$2&page=\$3&sort=\$4&order=\$5 last;
    rewrite "^/category-([0-9]+)-b([0-9]+)-([0-9]+)(.*)\.html\$" /category.php?id=\$1&brand=\$2&page=\$3 last;
    rewrite "^/category-([0-9]+)-b([0-9]+)(.*)\.html\$" /category.php?id=\$1&brand=\$2 last;
    rewrite "^/category-([0-9]+)(.*)\.html\$" /category.php?id=\$1 last;
    rewrite "^/goods-([0-9]+)(.*)\.html" /goods.php?id=\$1 last;
    rewrite "^/article_cat-([0-9]+)-([0-9]+)-(.+)-([a-zA-Z]+)(.*)\.html\$" /article_cat.php?id=\$1&page=\$2&sort=\$3&order=\$4 last;
    rewrite "^/article_cat-([0-9]+)-([0-9]+)(.*)\.html\$" /article_cat.php?id=\$1&page=\$2 last;
    rewrite "^/article_cat-([0-9]+)(.*)\.html\$" /article_cat.php?id=\$1 last;
    rewrite "^/article-([0-9]+)(.*)\.html\$" /article.php?id=\$1 last;
    rewrite "^/brand-([0-9]+)-c([0-9]+)-([0-9]+)-(.+)-([a-zA-Z]+)\.html" /brand.php?id=\$1&cat=\$2&page=\$3&sort=\$4&order=\$5 last;
    rewrite "^/brand-([0-9]+)-c([0-9]+)-([0-9]+)(.*)\.html" /brand.php?id=\$1&cat=\$2&page=\$3 last;
    rewrite "^/brand-([0-9]+)-c([0-9]+)(.*)\.html" /brand.php?id=\$1&cat=\$2 last;
    rewrite "^/brand-([0-9]+)(.*)\.html" /brand.php?id=\$1 last;
    rewrite "^/tag-(.*)\.html" /search.php?keywords=\$1 last;
    rewrite "^/snatch-([0-9]+)\.html\$" /snatch.php?id=\$1 last;
    rewrite "^/group_buy-([0-9]+)\.html\$" /group_buy.php?act=view&id=\$1 last;
    rewrite "^/auction-([0-9]+)\.html\$" /auction.php?act=view&id=\$1 last;
    rewrite "^/exchange-id([0-9]+)(.*)\.html\$" /exchange.php?id=\$1&act=view last;
    rewrite "^/exchange-([0-9]+)-min([0-9]+)-max([0-9]+)-([0-9]+)-(.+)-([a-zA-Z]+)(.*)\.html\$" /exchange.php?cat_id=\$1&integral_min=\$2&integral_max=\$3&page=\$4&sort=\$5&order=\$6 last;
    rewrite "^/exchange-([0-9]+)-([0-9]+)-(.+)-([a-zA-Z]+)(.*)\.html\$" /exchange.php?cat_id=\$1&page=\$2&sort=\$3&order=\$4 last;
    rewrite "^/exchange-([0-9]+)-([0-9]+)(.*)\.html\$" /exchange.php?cat_id=\$1&page=\$2 last;
    rewrite "^/exchange-([0-9]+)(.*)\.html\$" /exchange.php?cat_id=\$1 last;
}
EOrewrite_ecshop

cat >> "${REWRITE_CONFIG_PATH}/xenforo.conf" << EOrewrite_xenforo
location / {
    try_files \$uri \$uri/ /index.php?\$uri&\$args;
}
location /install/data/ { internal; }
location /install/templates/ { internal; }
location /internal_data/ { internal; }
location /library/ { internal; }
location /src/ { internal; }
EOrewrite_xenforo

cat >> "${REWRITE_CONFIG_PATH}/joomla.conf" << EOjoomla
location / {
    try_files \$uri \$uri/ /index.php?\$args;
}
EOjoomla

cat >> "${REWRITE_CONFIG_PATH}/laravel.conf" << EOlaravel
location / {
    try_files \$uri \$uri/ /index.php?\$query_string;
}
EOlaravel

cat >> "${REWRITE_CONFIG_PATH}/whmcs.conf" << EOwhmcs
location ~ /announcements/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/announcements/\$1;
}

location ~ /download/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/download\$1;
}

location ~ /knowledgebase/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/knowledgebase/\$1;
}

location ~ /store/ssl-certificates/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/store/ssl-certificates/\$1;
}

location ~ /store/sitelock/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/store/sitelock/\$1;
}

location ~ /store/website-builder/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/store/website-builder/\$1;
}

location ~ /store/order/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/store/order/\$1;
}

location ~ /cart/domain/renew/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/cart/domain/renew\$1;
}

location ~ /account/paymentmethods/?(.*)\$ {
    rewrite ^/(.*)\$ /index.php?rp=/account/paymentmethods\$1;
}

location ~ /admin/(addons|apps|domains|help\/license|services|setup|utilities\/system\/php-compat)(.*) {
    rewrite ^/(.*)\$ /admin/index.php?rp=/admin/\$1\$2 last;
}
EOwhmcs

cat >> "${REWRITE_CONFIG_PATH}/wordpress.conf" << EOwordpress
location / {
    try_files \$uri \$uri/ /index.php?\$args;
}
EOwordpress

cat >> "${REWRITE_CONFIG_PATH}/prestashop.conf" << EOprestashop
location / {
    rewrite ^/api/?(.*)\$ /webservice/dispatcher.php?url=\$1 last;
    rewrite ^/([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$1\$2.jpg last;
    rewrite ^/([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$1\$2\$3.jpg last;
    rewrite ^/([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$1\$2\$3\$4.jpg last;
    rewrite ^/([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$1\$2\$3\$4\$5.jpg last;
    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$1\$2\$3\$4\$5\$6.jpg last;
    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$6/\$1\$2\$3\$4\$5\$6\$7.jpg last;
    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$6/\$7/\$1\$2\$3\$4\$5\$6\$7\$8.jpg last;
    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$6/\$7/\$8/\$1\$2\$3\$4\$5\$6\$7\$8\$9.jpg last;
    rewrite ^/c/([0-9]+)(-[_a-zA-Z0-9-]*)(-[0-9]+)?/.+\.jpg\$ /img/c/\$1\$2.jpg last;
    rewrite ^/c/([a-zA-Z-]+)(-[0-9]+)?/.+\.jpg\$ /img/c/\$1.jpg last;
    rewrite ^/([0-9]+)(-[_a-zA-Z0-9-]*)(-[0-9]+)?/.+\.jpg\$ /img/c/\$1\$2.jpg last;

    try_files \$uri \$uri/ /index.php?\$args;
}
EOprestashop

cat >> "${REWRITE_CONFIG_PATH}/opencart.conf" << EOopencart
rewrite /admin\$ \$scheme://\$host\$uri/ permanent;
rewrite ^/download/(.*) /index.php?route=error/not_found last;
rewrite ^/image-smp/(.*) /index.php?route=product/smp_image&name=\$1 break;
location = /sitemap.xml {
    rewrite ^(.*)\$ /index.php?route=feed/google_sitemap break;
}
location = /googlebase.xml {
    rewrite ^(.*)\$ /index.php?route=feed/google_base break;
}
location / {
    # This try_files directive is used to enable SEO-friendly URLs for OpenCart
    try_files \$uri \$uri/ @opencart;
}
location @opencart {
    rewrite ^/(.+)\$ /index.php?_route_=\$1 last;
}
location /admin { index index.php; }
EOopencart

cat >> "${REWRITE_CONFIG_PATH}/yii.conf" << EOyii
location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
}
location ~ \.(js|css|png|jpg|gif|swf|ico|pdf|mov|fla|zip|rar)$ {
    try_files \$uri =404;
}
EOyii
}

# Config default server block
default_vhost(){
    NGINX_VHOST_PATH="/etc/nginx/conf.d"
    mkdir -p "${USR_DIR}"/nginx/auth
    mkdir -p /etc/nginx/apps
    if [[ -f "${NGINX_VHOST_PATH}/default.conf" ]]; then
        rm -rf "${NGINX_VHOST_PATH}"/default.conf
    fi

cat >> "/etc/nginx/apps/phpmyadmin.conf" <<EOphpmyadmin_vhost
location ^~ /phpmyadmin {
    root ${DEFAULT_DIR_TOOL}/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        include /etc/nginx/extra/nginx_limits.conf;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        if (-f \$request_filename)
        {
            fastcgi_pass php-app;
        }
    }
    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
location ~ ^/pma { rewrite ^/* /phpmyadmin last; }
location ^~ /phpmyadmin/locale/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/doc/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/log/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/tmp/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/libraries/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/templates/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/sql/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/vendor/ { deny all; access_log off; log_not_found off; }
location ^~ /phpmyadmin/examples/ { deny all; access_log off; log_not_found off; }
EOphpmyadmin_vhost

cat >> "/etc/nginx/apps/opcache.conf" <<EOopcache_vhost
location ^~ /opcache {
    root ${DEFAULT_DIR_TOOL}/;
    index index.php index.html index.htm;

    location ~ ^/opcache/(.+\.php)\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        include /etc/nginx/extra/nginx_limits.conf;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        if (-f \$request_filename)
        {
            fastcgi_pass php-app;
        }
    }
    location ~* ^/opcache/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
EOopcache_vhost

cat >> "/etc/nginx/apps/serverinfo.conf" <<EOserverinfo_vhost
location ^~ /serverinfo {
    root ${DEFAULT_DIR_TOOL}/;
    index index.php index.html index.htm;

    location ~ ^/serverinfo/(.+\.php)\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        include /etc/nginx/extra/nginx_limits.conf;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        if (-f \$request_filename)
        {
            fastcgi_pass php-app;
        }
    }
    location ~* ^/serverinfo/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
EOserverinfo_vhost

cat >> "/etc/nginx/apps/memcached.conf" <<EOmemcached_vhost
location ^~ /memcached {
    root ${DEFAULT_DIR_TOOL}/;
    index index.php index.html index.htm;

    auth_basic "Restricted";
    auth_basic_user_file ${USR_DIR}/nginx/auth/.htpasswd;

    location ~ ^/memcached/(.+\.php)\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        include /etc/nginx/extra/nginx_limits.conf;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        if (-f \$request_filename)
        {
            fastcgi_pass php-app;
        }
    }
    location ~* ^/memcached/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
EOmemcached_vhost

cat >> "/etc/nginx/apps/redis.conf" <<EOredis_vhost
location ^~ /redis {
    root ${DEFAULT_DIR_TOOL}/;
    index index.php index.html index.htm;

    location ~ ^/redis/(.+\.php)\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        include /etc/nginx/extra/nginx_limits.conf;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        if (-f \$request_filename)
        {
            fastcgi_pass php-app;
        }
    }
    location ~* ^/redis/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
EOredis_vhost

cat >> "/etc/nginx/web_apps.conf" << EOdefault_vhost
upstream php-app {
    server unix:/var/run/php-fpm.sock;
}

server {
    listen 80 default_server;
    root /usr/share/nginx/html/;
    index index.html index.htm;
    error_page 400 401 403 404 500 502 503 504 /50x.html;
}

server {
    listen ${RANDOM_ADMIN_PORT};

    server_name ${IPADDRESS};

    access_log off;
    log_not_found off;
    error_log /var/log/nginx_error.log;

    root ${DEFAULT_DIR_TOOL};
    index index.php index.html index.htm;

    auth_basic "Restricted";
    auth_basic_user_file ${USR_DIR}/nginx/auth/.htpasswd;

    include /etc/nginx/apps/phpmyadmin.conf;
    include /etc/nginx/apps/opcache.conf;
    include /etc/nginx/apps/serverinfo.conf;
    include /etc/nginx/apps/memcached.conf;
    include /etc/nginx/apps/redis.conf;

    location /nginx_status {
        stub_status on;
        access_log   off;
        allow 127.0.0.1;
        allow ${IPADDRESS};
        deny all;
    }

    location /php_status {
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
        allow 127.0.0.1;
        allow ${IPADDRESS};
        deny all;
    }

    error_page 400 401 403 404 500 502 503 504 /50x.html;
    include /etc/nginx/extra/security.conf;
    include /etc/nginx/extra/staticfiles.conf;
}
EOdefault_vhost
}

default_index(){
    if [[ -f "${DEFAULT_DIR_WEB}/index.html" ]]; then
        rm -rf "${DEFAULT_DIR_WEB}"/index.html
    fi

    cat >> "${DEFAULT_DIR_WEB}/index.html" << EOdefault_index
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Site Maintenance</title>
        <style>
          body{text-align:center;padding:150px}
          h1{font-size:50px}
          body{font:20px Helvetica,sans-serif;color:#333}
          article{display:block;text-align:left;max-width:650px;margin:0 auto}
          a{color:#dc8100;text-decoration:none}
          a:hover{color:#333;text-decoration:none}
        </style>
    </head>
    <body>
        <article>
            <h1>We'll be back soon!</h1>
            <div>
                <p>Sorry for the inconvenience but we're performing some maintenance at the moment. If you need to you can always
                <a href="mailto:${ADMIN_EMAIL}">contact us</a>, otherwise we'll be back online shortly!</p>
            </div>
        </article>
    </body>
</html>
EOdefault_index

    cp "${DEFAULT_DIR_WEB}"/index.html ${DEFAULT_DIR_TOOL}/index.html
}

default_error_page(){
    if [[ -f "${DEFAULT_DIR_WEB}/50x.html" ]]; then
        rm -rf "${DEFAULT_DIR_WEB}"/50x.html
    fi
    cat >> "${DEFAULT_DIR_WEB}/50x.html" << EOdefault_index
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Error</title>
        <style>
          body{text-align:center;padding:150px}
          h1{font-size:50px}
          body{font:20px Helvetica,sans-serif;color:#333}
          article{display:block;text-align:left;max-width:650px;margin:0 auto}
          a{color:#dc8100;text-decoration:none}
          a:hover{color:#333;text-decoration:none}
        </style>
    </head>
    <body>
        <article>
            <h1>An error occurred.</h1>
            <div>
                <p>Sorry, the page you are looking for is currently unavailable. Please try again later. If you need to you can always
                <a href="mailto:${ADMIN_EMAIL}">contact us</a>, otherwise we'll be back online shortly!</p>
            </div>
        </article>
    </body>
</html>
EOdefault_index

    cp "${DEFAULT_DIR_WEB}"/50x.html ${DEFAULT_DIR_TOOL}/50x.html
}

wprocket_nginx(){
    cd_dir /etc/nginx
    git clone https://github.com/satellitewp/rocket-nginx.git
    cd_dir /etc/nginx/rocket-nginx
    cp rocket-nginx.ini.disabled rocket-nginx.ini
    php rocket-parser.php
}


############################################
# Config PHP-FPM
############################################
# PHP Parameter
php_parameter(){
    if [[ ${CPU_CORES} -ge 4 && ${CPU_CORES} -lt 6 && ${RAM_TOTAL} -gt 1049576 && ${RAM_TOTAL} -le 2097152 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 4 && ${CPU_CORES} -lt 6 && ${RAM_TOTAL} -gt 2097152 && ${RAM_TOTAL} -le 3145728 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 4 && ${CPU_CORES} -lt 6 && ${RAM_TOTAL} -gt 3145728 && ${RAM_TOTAL} -le 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 4 && ${CPU_CORES} -lt 6 && ${RAM_TOTAL} -gt 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 6 && ${CPU_CORES} -lt 8 && ${RAM_TOTAL} -gt 3145728 && ${RAM_TOTAL} -le 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 6 && ${CPU_CORES} -lt 8 && ${RAM_TOTAL} -gt 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 8 && ${CPU_CORES} -lt 16 && ${RAM_TOTAL} -gt 3145728 && ${RAM_TOTAL} -le 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 8 && ${CPU_CORES} -lt 12 && ${RAM_TOTAL} -gt 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 13 && ${CPU_CORES} -lt 16 && ${RAM_TOTAL} -gt 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 6))
        PM_MAX_REQUEST=2000
    elif [[ ${CPU_CORES} -ge 17 && ${RAM_TOTAL} -gt 4194304 ]]; then
        PM_MAX_CHILDREN=$((CPU_CORES * 5))
        PM_MAX_REQUEST=2000
    else
        PM_MAX_CHILDREN=$((CPU_CORES * 5))
        PM_MAX_REQUEST=500
    fi
}

php_global_config(){
    php_parameter
    if [[ -f "/etc/php-fpm.conf" ]]; then
        mv /etc/php-fpm.conf /etc/php-fpm.conf.orig
    fi
    if [[ ! -d "/var/run/php-fpm" ]]; then
        mkdir -p /var/run/php-fpm
    fi
    cat >> "/etc/php-fpm.conf" << EOphp_fpm_conf
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

include=/etc/php-fpm.d/*.conf

[global]
pid = /var/run/php-fpm/php-fpm.pid
error_log = /var/log/php-fpm/error.log
log_level = warning
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes
EOphp_fpm_conf

    if [[ -f "/etc/php-fpm.d/www.conf" ]]; then
        mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.orig
    fi
cat >> "/etc/php-fpm.d/www.conf" << EOwww_conf
[www]
listen = /var/run/php-fpm.sock;
listen.allowed_clients = 127.0.0.1
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
user = nginx
group = nginx
pm = ondemand
pm.max_children = ${PM_MAX_CHILDREN}
pm.max_requests = ${PM_MAX_REQUEST}
pm.process_idle_timeout = 20
;slowlog = /var/log/php-fpm/www-slow.log
chdir = /
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
php_admin_value[disable_functions] = exec,system,passthru,shell_exec,dl,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname
;php_admin_value[disable_functions] = exec,system,passthru,shell_exec,proc_close,proc_open,dl,popen,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname
;php_admin_value[open_basedir] = ${DEFAULT_DIR_TOOL}/:/tmp/:/var/tmp/:/dev/urandom:/usr/share/php/:/dev/shm:/var/lib/php/sessions/
security.limit_extensions = .php
EOwww_conf

    if [[ ! -d "/var/lib/php/session" ]]; then
        mkdir -p /var/lib/php/session
    fi
    if [[ ! -d "/var/lib/php/wsdlcache" ]]; then
        mkdir -p /var/lib/php/wsdlcache
    fi
    if [[ ! -d "/var/log/php-fpm" ]]; then
        mkdir -p /var/log/php-fpm
    fi
    chown -R nginx:nginx /var/lib/php/session
    chown -R nginx:nginx /var/lib/php/wsdlcache
    chown -R nginx:nginx /var/log/php-fpm
    chmod 755 /var/lib/php/session
    chmod 755 /var/lib/php/wsdlcache
}

php_global_config_2(){
    php2_fpm_config_file="/etc/opt/remi/${PHP_VERSION_2}/php-fpm.conf"
    php2_fpm_config_path="/etc/opt/remi/${PHP_VERSION_2}/php-fpm.d"
    www2_config_file="/etc/opt/remi/${PHP_VERSION_2}/php-fpm.d/www.conf"

    if [[ ${PHP_VERSION_2} == "php56" ]]; then
        php2_fpm_config_file="/opt/remi/${PHP_VERSION_2}/root/etc/php-fpm.conf"
        php2_fpm_config_path="/opt/remi/php56/root/etc/php-fpm.d"
        www2_config_file="/opt/remi/${PHP_VERSION_2}/root/etc/php-fpm.d"
    fi

    if [[ -f "${php2_fpm_config_file}" ]]; then
        mv "${php2_fpm_config_file}" "${php2_fpm_config_file}".orig
    fi

    if [[ ! -d "/opt/remi/${PHP_VERSION_2}/root/var/run/php-fpm" ]]; then
        mkdir -p /opt/remi/"${PHP_VERSION_2}"/root/var/run/php-fpm
    fi

    cat >> "${php2_fpm_config_file}" << EOphp_fpm_2_conf
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

include=${php2_fpm_config_path}/*.conf

[global]
pid = /opt/remi/${PHP_VERSION_2}/root/var/run/php-fpm/php-fpm.pid
error_log = /opt/remi/${PHP_VERSION_2}/root/var/log/php-fpm/error.log
log_level = warning
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes
EOphp_fpm_2_conf

    if [[ -f "${www2_config_file}" ]]; then
        mv "${www2_config_file}" "${www2_config_file}".orig
    fi
cat >> "${www2_config_file}" << EOwww_2_conf
[www]
listen = /opt/remi/${PHP_VERSION_2}/root/var/run/php-fpm/php-fpm.sock;
listen.allowed_clients = 127.0.0.1
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
user = nginx
group = nginx
pm = ondemand
pm.max_children = ${PM_MAX_CHILDREN}
pm.max_requests = ${PM_MAX_REQUEST}
pm.process_idle_timeout = 20
;slowlog = /opt/remi/${PHP_VERSION_2}/root/var/log/php-fpm/www-slow.log
chdir = /
php_admin_value[error_log] = /opt/remi/${PHP_VERSION_2}/root/var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /opt/remi/${PHP_VERSION_2}/root/var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /opt/remi/${PHP_VERSION_2}/root/var/lib/php/wsdlcache
php_admin_value[disable_functions] = exec,system,passthru,shell_exec,dl,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname
;php_admin_value[open_basedir] = ${DEFAULT_DIR_WEB}/:${DEFAULT_DIR_TOOL}/:/tmp/:/var/tmp/:/dev/urandom:/usr/share/php/:/dev/shm:/var/lib/php/sessions/
security.limit_extensions = .php
EOwww_2_conf

    if [[ ! -d "/opt/remi/${PHP_VERSION_2}/root/var/lib/php/session" ]]; then
        mkdir -p /opt/remi/"${PHP_VERSION_2}"/root/var/lib/php/session
    fi
    if [[ ! -d "/opt/remi/${PHP_VERSION_2}/root/var/lib/php/wsdlcache" ]]; then
        mkdir -p /opt/remi/"${PHP_VERSION_2}"/root/var/lib/php/wsdlcache
    fi
    if [[ ! -d "/opt/remi/${PHP_VERSION_2}/root/var/log/php-fpm" ]]; then
        mkdir -p /opt/remi/"${PHP_VERSION_2}"/root/var/log/php-fpm
    fi
    chown -R nginx:nginx /opt/remi/"${PHP_VERSION_2}"/root/var/lib/php/session
    chown -R nginx:nginx /opt/remi/"${PHP_VERSION_2}"/root/var/lib/php/wsdlcache
    chown -R nginx:nginx /opt/remi/"${PHP_VERSION_2}"/root/var/log/php-fpm
    chmod 711 /opt/remi/"${PHP_VERSION_2}"/root/var/lib/php/session
    chmod 711 /opt/remi/"${PHP_VERSION_2}"/root/var/lib/php/wsdlcache
}

# Custom PHP Ini
hostvn_custom_ini(){
    cat > "/etc/php.d/00-hostvn-custom.ini" <<EOhostvn_custom_ini
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 300
max_input_time = 300
short_open_tag = On
realpath_cache_size = ${PHP_REAL_PATH_LIMIT}
realpath_cache_ttl = ${PHP_REAL_PATH_TTL}
memory_limit = ${MAX_MEMORY}M
upload_max_filesize = ${MAX_MEMORY}M
post_max_size = ${MAX_MEMORY}M
expose_php = Off
display_errors = Off
mail.add_x_header = Off
max_input_nesting_level = 128
max_input_vars = ${MAX_INPUT_VARS}
mysqlnd.net_cmd_buffer_size = 16384
mysqlnd.collect_memory_statistics = Off
mysqlnd.mempool_default_size = 16000
always_populate_raw_post_data=-1
EOhostvn_custom_ini
}

hostvn_custom_ini_2(){
    cat > "${PHP2_INI_PATH}/00-hostvn-custom.ini" <<EOhostvn_custom_ini
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 300
max_input_time = 300
short_open_tag = On
realpath_cache_size = ${PHP_REAL_PATH_LIMIT}
realpath_cache_ttl = ${PHP_REAL_PATH_TTL}
memory_limit = ${MAX_MEMORY}M
upload_max_filesize = ${MAX_MEMORY}M
post_max_size = ${MAX_MEMORY}M
expose_php = Off
display_errors = Off
mail.add_x_header = Off
max_input_nesting_level = 128
max_input_vars = ${MAX_INPUT_VARS}
mysqlnd.net_cmd_buffer_size = 16384
mysqlnd.collect_memory_statistics = Off
mysqlnd.mempool_default_size = 16000
always_populate_raw_post_data=-1
EOhostvn_custom_ini
}

# Config PHP Opcache
php_opcache(){
    if [[ -f "/etc/php.d/10-opcache.ini" ]]; then
        mv /etc/php.d/10-opcache.ini /etc/php.d/10-opcache.ini.orig
    fi
    cat > "/etc/php.d/10-opcache.ini" << EOphp_opcache
zend_extension=opcache.so
opcache.enable=1
opcache.memory_consumption=${OPCACHE_MEM}
opcache.interned_strings_buffer=8
opcache.max_wasted_percentage=5
opcache.max_accelerated_files=65407
opcache.revalidate_freq=180
opcache.fast_shutdown=0
opcache.enable_cli=0
opcache.save_comments=1
opcache.enable_file_override=1
opcache.validate_timestamps=1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
EOphp_opcache

    cat > "/etc/php.d/opcache-default.blacklist" << EOopcache_blacklist
/home/*/*/public_html/wp-content/plugins/backwpup/*
/home/*/*/public_html/wp-content/plugins/duplicator/*
/home/*/*/public_html/wp-content/plugins/updraftplus/*
/home/*/*/public_html/storage/*
EOopcache_blacklist
}

php_opcache_2(){
    if [[ -f "${PHP2_INI_PATH}/10-opcache.ini" ]]; then
        mv "${PHP2_INI_PATH}"/10-opcache.ini "${PHP2_INI_PATH}"/10-opcache.ini.orig
    fi
    cat > "${PHP2_INI_PATH}/10-opcache.ini" << EOphp_opcache
zend_extension=opcache.so
opcache.enable=1
opcache.memory_consumption=${OPCACHE_MEM}
opcache.interned_strings_buffer=8
opcache.max_wasted_percentage=5
opcache.max_accelerated_files=65407
opcache.revalidate_freq=180
opcache.fast_shutdown=0
opcache.enable_cli=0
opcache.save_comments=1
opcache.enable_file_override=1
opcache.validate_timestamps=1
opcache.blacklist_filename=${PHP2_INI_PATH}/opcache-default.blacklist
EOphp_opcache

    cat > "${PHP2_INI_PATH}/opcache-default.blacklist" << EOopcache_blacklist
/home/*/*/public_html/wp-content/plugins/backwpup/*
/home/*/*/public_html/wp-content/plugins/duplicator/*
/home/*/*/public_html/wp-content/plugins/updraftplus/*
/home/*/*/public_html/storage/*
EOopcache_blacklist
}

############################################
# Config MariaDB
############################################
# MariaDB calculation
mariadb_calculation(){
    if [[ ${RAM_TOTAL} -gt 400000 && ${RAM_TOTAL} -le 2099152 ]]; then #1GB Ram
        max_allowed_packet="32M"
        back_log="100"
        max_connections="150"
        key_buffer_size="32M"
        myisam_sort_buffer_size="32M"
        myisam_max_sort_file_size="2048M"
        innodb_log_buffer_size="8M"
        join_buffer_size="64K"
        read_buffer_size="64K"
        sort_buffer_size="128K"
        table_definition_cache="4096"
        table_open_cache="2048"
        thread_cache_size="64"
        tmp_table_size="32M"
        max_heap_table_size="32M"
        query_cache_limit="512K"
        query_cache_size="16M"
        innodb_open_files="2000"
        innodb_buffer_pool_size="48M"
        innodb_io_capacity="100"
        aria_pagecache_buffer_size="8M"
        aria_sort_buffer_size="8M"
        net_buffer_length="8192"
        read_rnd_buffer_size="256K"
        innodb_log_file_size="128M"
        innodb_read_io_threads="2"
        aria_log_file_size="32M"
        key_buffer="32M "
        sort_buffer="16M"
        read_buffer="16M"
        write_buffer="16M"
    fi

    if [[ ${RAM_TOTAL} -gt 2099152 && ${RAM_TOTAL} -le 4198304 ]]; then #2GB Ram
        max_allowed_packet="48M"
        back_log="200"
        max_connections="200"
        key_buffer_size="32M"
        myisam_sort_buffer_size="64M"
        myisam_max_sort_file_size="2048M"
        innodb_log_buffer_size="8M"
        join_buffer_size="128K"
        read_buffer_size="128K"
        sort_buffer_size="256K"
        table_definition_cache="8192"
        table_open_cache="4096"
        thread_cache_size="128"
        tmp_table_size="128M"
        max_heap_table_size="128M"
        query_cache_limit="1024K"
        query_cache_size="64M"
        innodb_open_files="4000"
        innodb_buffer_pool_size="192M"
        innodb_io_capacity="200"
        aria_pagecache_buffer_size="32M"
        aria_sort_buffer_size="32M"
        net_buffer_length="8192"
        read_rnd_buffer_size="256K"
        innodb_log_file_size="128M"
        innodb_read_io_threads="2"
        aria_log_file_size="32M"
        key_buffer="32M "
        sort_buffer="16M"
        read_buffer="16M"
        write_buffer="16M"
    fi

    if [[ ${RAM_TOTAL} -gt 4198304 && ${RAM_TOTAL} -le 8396608 ]]; then #4GB Ram
        max_allowed_packet="64M"
        back_log="200"
        max_connections="350"
        key_buffer_size="256M"
        myisam_sort_buffer_size="256M"
        myisam_max_sort_file_size="2048M"
        innodb_log_buffer_size="8M"
        join_buffer_size="256K"
        read_buffer_size="256K"
        sort_buffer_size="256K"
        table_definition_cache="8192"
        table_open_cache="4096"
        thread_cache_size="256"
        tmp_table_size="256M"
        max_heap_table_size="256M"
        query_cache_limit="1024K"
        query_cache_size="80M"
        innodb_open_files="4000"
        innodb_buffer_pool_size="512M"
        innodb_io_capacity="300"
        aria_pagecache_buffer_size="64M"
        aria_sort_buffer_size="64M"
        net_buffer_length="16384"
        read_rnd_buffer_size="512K"
        innodb_log_file_size="256M"
        innodb_read_io_threads="4"
        aria_log_file_size="64M"
        key_buffer="256M "
        sort_buffer="32M"
        read_buffer="32M"
        write_buffer="32M"
    fi

    if [[ ${RAM_TOTAL} -gt 8396608 && ${RAM_TOTAL} -le 16793216 ]]; then #8GB Ram
        max_allowed_packet="64M"
        back_log="512"
        max_connections="400"
        key_buffer_size="384M"
        myisam_sort_buffer_size="256M"
        myisam_max_sort_file_size="2048M"
        innodb_log_buffer_size="16M"
        join_buffer_size="256K"
        read_buffer_size="256K"
        sort_buffer_size="512K"
        table_definition_cache="8192"
        table_open_cache="8192"
        thread_cache_size="256"
        tmp_table_size="512M"
        max_heap_table_size="512M"
        query_cache_limit="1024K"
        query_cache_size="128M"
        innodb_open_files="8000"
        innodb_buffer_pool_size="1024M"
        innodb_io_capacity="400"
        aria_pagecache_buffer_size="64M"
        aria_sort_buffer_size="64M"
        net_buffer_length="16384"
        read_rnd_buffer_size="512K"
        innodb_log_file_size="384M"
        innodb_read_io_threads="4"
        aria_log_file_size="64M"
        key_buffer="384M "
        sort_buffer="64M"
        read_buffer="64M"
        write_buffer="64M"
    fi

    if [[ ${RAM_TOTAL} -gt 16793216 && ${RAM_TOTAL} -le 33586432 ]]; then #16GB Ram
        max_allowed_packet="64M"
        back_log="768"
        max_connections="500"
        key_buffer_size="512M"
        myisam_sort_buffer_size="512M"
        myisam_max_sort_file_size="4096M"
        innodb_log_buffer_size="32M"
        join_buffer_size="1M"
        read_buffer_size="1M"
        sort_buffer_size="2M"
        table_definition_cache="10240"
        table_open_cache="10240"
        thread_cache_size="384"
        tmp_table_size="768M"
        max_heap_table_size="768M"
        query_cache_limit="1024K"
        query_cache_size="160M"
        innodb_open_files="10000"
        innodb_buffer_pool_size="4096M"
        innodb_io_capacity="500"
        aria_pagecache_buffer_size="128M"
        aria_sort_buffer_size="128M"
        net_buffer_length="16384"
        read_rnd_buffer_size="512K"
        innodb_log_file_size="640M"
        innodb_read_io_threads="4"
        aria_log_file_size="64M"
        key_buffer="768M "
        sort_buffer="128M"
        read_buffer="128M"
        write_buffer="128M"
    fi

    if [[ "$(expr "${RAM_TOTAL}" \>= 33586432)" = "1" ]]; then #32GB Ram
        max_allowed_packet="64M"
        back_log="1024"
        max_connections="600"
        key_buffer_size="768M"
        myisam_sort_buffer_size="768M"
        myisam_max_sort_file_size="8192M"
        innodb_log_buffer_size="64M"
        join_buffer_size="2M"
        read_buffer_size="2M"
        sort_buffer_size="2M"
        table_definition_cache="10240"
        table_open_cache="10240"
        thread_cache_size="384"
        tmp_table_size="1024M"
        max_heap_table_size="1024M"
        query_cache_limit="1536K"
        query_cache_size="256M"
        innodb_open_files="10000"
        innodb_buffer_pool_size="8192M"
        innodb_io_capacity="600"
        aria_pagecache_buffer_size="128M"
        aria_sort_buffer_size="128M"
        net_buffer_length="16384"
        read_rnd_buffer_size="512K"
        innodb_log_file_size="768M"
        innodb_read_io_threads="4"
        aria_log_file_size="64M"
        key_buffer="1024M "
        sort_buffer="256M"
        read_buffer="256M"
        write_buffer="256M"
    fi

    if [[ "$(expr "${RAM_TOTAL}" \>= 64000000)" = "1" ]]; then #64GB Ram
        max_allowed_packet="80M"
        back_log="1024"
        max_connections="800"
        key_buffer_size="1024M"
        myisam_sort_buffer_size="1024M"
        myisam_max_sort_file_size="10240M"
        innodb_log_buffer_size="64M"
        join_buffer_size="2M"
        read_buffer_size="2M"
        sort_buffer_size="2M"
        table_definition_cache="10240"
        table_open_cache="10240"
        thread_cache_size="384"
        tmp_table_size="1536M"
        max_heap_table_size="1536M"
        query_cache_limit="1536K"
        query_cache_size="256M"
        innodb_open_files="10000"
        innodb_buffer_pool_size="12288M"
        innodb_io_capacity="800"
        aria_pagecache_buffer_size="256M"
        aria_sort_buffer_size="256M"
        net_buffer_length="16384"
        read_rnd_buffer_size="512K"
        innodb_log_file_size="1024M"
        innodb_read_io_threads="4"
        aria_log_file_size="128M"
        key_buffer="1536M "
        sort_buffer="384M"
        read_buffer="384M"
        write_buffer="384M"
    fi
}

config_my_cnf(){
    mariadb_calculation
    mkdir -p /var/log/mysql
    chown -R mysql:mysql /var/log/mysql
    mv /etc/my.cnf /etc/my.cnf.orig

cat >> "/etc/my.cnf" << EOmy_cnf
[client]
socket=/var/lib/mysql/mysql.sock

[mysql]
max_allowed_packet = ${max_allowed_packet}

[mysqld]
local-infile=0
ignore-db-dir=lost+found
#character-set-server=utf8
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

#bind-address=127.0.0.1

tmpdir=/tmp

innodb=ON
#skip-federated
#skip-pbxt
#skip-pbxt_statistics
#skip-archive
#skip-name-resolve
#old_passwords
back_log = ${back_log}
max_connections = ${max_connections}
key_buffer_size = ${key_buffer_size}
myisam_sort_buffer_size = ${myisam_sort_buffer_size}
myisam_max_sort_file_size = ${myisam_max_sort_file_size}
join_buffer_size = ${join_buffer_size}
read_buffer_size = ${read_buffer_size}
sort_buffer_size = ${sort_buffer_size}
table_definition_cache = ${table_definition_cache}
table_open_cache = ${table_open_cache}
thread_cache_size = ${thread_cache_size}
wait_timeout = 1800
connect_timeout = 10
tmp_table_size = ${tmp_table_size}
max_heap_table_size = ${max_heap_table_size}
max_allowed_packet = ${max_allowed_packet}
#max_seeks_for_key = 4294967295
#group_concat_max_len = 1024
max_length_for_sort_data = 1024
net_buffer_length = ${net_buffer_length}
max_connect_errors = 100000
concurrent_insert = 2
read_rnd_buffer_size = ${read_rnd_buffer_size}
bulk_insert_buffer_size = 8M
# query_cache boost for MariaDB >10.1.2+
query_cache_limit = ${query_cache_limit}
query_cache_size = ${query_cache_size}
query_cache_type = 1
query_cache_min_res_unit = 2K
query_prealloc_size = 262144
query_alloc_block_size = 65536
transaction_alloc_block_size = 8192
transaction_prealloc_size = 4096
default-storage-engine = InnoDB

log_warnings=1
slow_query_log=0
long_query_time=1
slow_query_log_file=/var/lib/mysql/slowq.log
log-error=/var/log/mysql/mysqld.log

# innodb settings
#innodb_large_prefix=1
innodb_purge_threads=1
#innodb_file_format = Barracuda
innodb_file_per_table = 1
innodb_open_files = ${innodb_open_files}
innodb_data_file_path= ibdata1:10M:autoextend
innodb_buffer_pool_size = ${innodb_buffer_pool_size}

## https://mariadb.com/kb/en/mariadb/xtradbinnodb-server-system-variables/#innodb_buffer_pool_instances
#innodb_buffer_pool_instances=2

#innodb_log_files_in_group = 2
innodb_log_file_size = ${innodb_log_file_size}
innodb_log_buffer_size = ${innodb_log_buffer_size}
innodb_flush_log_at_trx_commit = 2
innodb_thread_concurrency = 0
innodb_lock_wait_timeout=50
innodb_flush_method = O_DIRECT
#innodb_support_xa=1

# 200 * # DISKS
innodb_io_capacity = ${innodb_io_capacity}
innodb_io_capacity_max = 2000
innodb_read_io_threads = ${innodb_read_io_threads}
innodb_write_io_threads = 2
innodb_flush_neighbors = 1

# mariadb settings
[mariadb]
#thread-handling = pool-of-threads
#thread-pool-size= 20
#mysql --port=3307 --protocol=tcp
#extra-port=3307
#extra-max-connections=1

userstat = 0
key_cache_segments = 1
aria_group_commit = none
aria_group_commit_interval = 0
aria_log_file_size = ${aria_log_file_size}
aria_log_purge_type = immediate
aria_pagecache_buffer_size = ${aria_pagecache_buffer_size}
aria_sort_buffer_size = ${aria_sort_buffer_size}

[mariadb-5.5]
innodb_file_format = Barracuda
innodb_file_per_table = 1

#ignore_db_dirs=
query_cache_strip_comments=0

innodb_read_ahead = linear
innodb_adaptive_flushing_method = estimate
innodb_flush_neighbor_pages = 1
innodb_stats_update_need_lock = 0
innodb_log_block_size = 512

log_slow_filter =admin,filesort,filesort_on_disk,full_join,full_scan,query_cache,query_cache_miss,tmp_table,tmp_table_on_disk

[mysqld_safe]
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mysql/mysqld.log
#nice = -5
open-files-limit = 8192

[mysqldump]
quick
max_allowed_packet = ${max_allowed_packet}

[myisamchk]
tmpdir=/tmp
key_buffer = ${key_buffer}
sort_buffer = ${sort_buffer}
read_buffer = ${read_buffer}
write_buffer = ${write_buffer}

[mysqlhotcopy]
interactive-timeout

[mariadb-10.0]
innodb_file_format = Barracuda
innodb_file_per_table = 1

# 2 variables needed to switch from XtraDB to InnoDB plugins
#plugin-load=ha_innodb
#ignore_builtin_innodb

## MariaDB 10 only save and restore buffer pool pages
## warm up InnoDB buffer pool on server restarts
innodb_buffer_pool_dump_at_shutdown=1
innodb_buffer_pool_load_at_startup=1
innodb_buffer_pool_populate=0
## Disabled settings
performance_schema=OFF
innodb_stats_on_metadata=OFF
innodb_sort_buffer_size=2M
innodb_online_alter_log_max_size=128M
query_cache_strip_comments=0
log_slow_filter =admin,filesort,filesort_on_disk,full_join,full_scan,query_cache,query_cache_miss,tmp_table,tmp_table_on_disk
EOmy_cnf
}

# Set MariaDB Root Password
set_mariadb_root_pwd(){
    SQLPASS=$(generate_random_pwd)

    cat > "/root/.my.cnf" <<EOmy_conf
[client]
user=root
password=${SQLPASS}
EOmy_conf

    chmod 600 /root/.my.cnf

    if [[ "${OS_VER}" -eq 8 ]]; then
/usr/bin/mysql_secure_installation << EOF

Y
${SQLPASS}
${SQLPASS}
Y
Y
Y
Y
EOF
    else
/usr/bin/mysql_secure_installation << EOF

n
Y
${SQLPASS}
${SQLPASS}
Y
Y
Y
Y
EOF
    fi
}

create_mysql_user(){
    cat > "/tmp/mysql_query.temp" <<EOquery_temp
    CREATE USER 'admin'@'localhost' IDENTIFIED BY '${SQLPASS}';
    GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOquery_temp

    mysql -uroot -p"${SQLPASS}" < /tmp/mysql_query.temp
    rm -f /tmp/mysql_query.temp
}

############################################
# Other Config
############################################

limits_config(){
    mv /etc/security/limits.conf /etc/security/limits.conf.orig
    cat >> "/etc/security/limits.conf" <<EOlimits_config
* soft nofile 524288
* hard nofile 524288
nginx soft nofile 262144
nginx hard nofile 524288
nobody soft nofile 524288
nobody hard nofile 524288
root soft nofile 524288
root hard nofile 524288
EOlimits_config
    ulimit -n 524288

    if [ "${OS_VER}" = "7" ]; then
        if [[ -f "/etc/security/limits.d/20-nproc.conf" ]]; then
            mv /etc/security/limits.d/20-nproc.conf /etc/security/limits.d/20-nproc.conf.orig
            cat > "/etc/security/limits.d/20-nproc.conf" <<EOnproc
    # Default limit for number of user's processes to prevent
    # accidental fork bombs.
    # See rhbz #432903 for reasoning.

    *          soft    nproc     8192
    *          hard    nproc     8192
    nginx      soft    nproc     32278
    nginx      hard    nproc     32278
    root       soft    nproc     unlimited
EOnproc
        fi
    fi
}

sysctl_config(){
    if [ "${OS_VER}" = "7" ]; then
        if [ ! -f "/etc/sysctl.d/101-sysctl.conf" ]; then
            touch /etc/sysctl.d/101-sysctl.conf
        fi
        echo "" > /etc/sysctl.d/101-sysctl.conf
        cat >> "/etc/sysctl.d/101-sysctl.conf" <<EO101_sysctl
kernel.printk=4 1 1 7
fs.nr_open=12000000
fs.file-max=9000000
net.core.wmem_max=16777216
net.core.rmem_max=16777216
net.ipv4.tcp_rmem=8192 87380 16777216
net.ipv4.tcp_wmem=8192 65536 16777216
net.core.netdev_max_backlog=65536
net.core.somaxconn=65535
net.core.optmem_max=8192
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_time=240
net.ipv4.tcp_max_syn_backlog=65536
net.ipv4.tcp_sack=1
net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_max_tw_buckets = 1440000
vm.swappiness=10
vm.min_free_kbytes=65536
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_limit_output_bytes=65536
net.ipv4.tcp_rfc1337=1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.netfilter.nf_conntrack_helper=0
net.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 28800
net.netfilter.nf_conntrack_generic_timeout = 60
net.ipv4.tcp_challenge_ack_limit = 999999999
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_base_mss = 1024
net.unix.max_dgram_qlen = 4096
EO101_sysctl
        if [[ "$(grep -o 'AMD EPYC' /proc/cpuinfo | sort -u)" = 'AMD EPYC' ]]; then
            echo "kernel.watchdog_thresh = 20" >> /etc/sysctl.d/101-sysctl.conf
        fi

        /sbin/sysctl --system
        sed -i 's/vm.swappiness/#vm.swappiness/g' /usr/lib/tuned/virtual-guest/tuned.conf
        echo "vm.swappiness = 10" >> /usr/lib/tuned/virtual-guest/tuned.conf
    fi
}

############################################
# Log Rotation
############################################
log_rotation(){
    cat > "/etc/logrotate.d/nginx" << EOnginx_log
/home/*/logs/access.log /home/*/logs/error.log /home/*/logs/nginx_error.log {
    create 640 nginx nginx
        daily
    dateext
        missingok
        rotate 5
        maxage 7
        compress
    size=100M
        notifempty
        sharedscripts
        postrotate
                [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
        endscript
    su nginx nginx
}
EOnginx_log
cat > "/etc/logrotate.d/php-fpm" << EOphp_fpm_log
/home/*/logs/php-fpm*.log {
        daily
    dateext
        compress
        maxage 7
        missingok
        notifempty
        sharedscripts
        size=100M
        postrotate
            /bin/kill -SIGUSR1 \`cat /var/run/php-fpm/php-fpm.pid 2>/dev/null\` 2>/dev/null || true
        endscript
    su nginx nginx
}
EOphp_fpm_log
cat > "/etc/logrotate.d/mysql" << EOmysql_log
/home/*/logs/mysql*.log {
        create 640 mysql mysql
        notifempty
        daily
        rotate 3
        maxage 7
        missingok
        compress
        postrotate
        # just if mysqld is really running
        if test -x /usr/bin/mysqladmin && \
           /usr/bin/mysqladmin ping &>/dev/null
        then
           /usr/bin/mysqladmin flush-logs
        fi
        endscript
    su mysql mysql
}
EOmysql_log
}

############################################
# Install phpMyAdmin
############################################
#Config phpMyAdmin
config_phpmyadmin(){
    BLOWFISH_SECRET=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c100)
    rm -rf "${DEFAULT_DIR_TOOL}"/phpmyadmin/setup
    mkdir -p "${DEFAULT_DIR_TOOL}"/phpmyadmin/tmp

    if [[ "${PHP_VERSION}" != "php56" ]]; then
        DECLARE="declare(strict_types=1);"
    fi

    cat > "${DEFAULT_DIR_TOOL}/phpmyadmin/config.inc.php" <<EOCONFIGINC
<?php
${DECLARE}
\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['connect_type'] = 'tcp';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['PmaNoRelation_DisableWarning'] = true;
\$cfg['VersionCheck'] = false;
\$cfg['TempDir'] = '${DEFAULT_DIR_TOOL}/phpmyadmin/tmp';
\$cfg['CaptchaLoginPublicKey'] = '';
\$cfg['CaptchaLoginPrivateKey'] = '';
\$cfg['ExecTimeLimit'] = 600;
EOCONFIGINC

    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/phpmyadmin
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/phpmyadmin
}

create_phpmyadmin_db(){
    cat > "/tmp/phpmyadmin.temp" << EOphpmyadmin_temp
CREATE DATABASE phpmyadmin COLLATE utf8_general_ci;
FLUSH PRIVILEGES;
EOphpmyadmin_temp

    mysql -u root -p"${SQLPASS}" < /tmp/phpmyadmin.temp
    rm -f /tmp/phpmyadmin.temp

    curl -o phpmyadmin.sql "${EXT_LINK}"/phpmyadmin.sql
    mysql -u root -p"${SQLPASS}" phpmyadmin < phpmyadmin.sql
    rm -rf phpmyadmin.sql
}

install_phpmyadmin(){
    # Singapore Local
    #echo "89.187.162.49 files.phpmyadmin.net" >> /etc/hosts

    if [[ "${PHP_VERSION}" == "php56" ]]; then
        PHPMYADMIN_VERSION="4.9.5"
    fi

    cd_dir "${DEFAULT_DIR_TOOL}"
    wget "${PMA_LINK}"/"${PHPMYADMIN_VERSION}"/phpMyAdmin-"${PHPMYADMIN_VERSION}"-english.zip
    unzip phpMyAdmin-"${PHPMYADMIN_VERSION}"-english.zip
    rm -rf "${DEFAULT_DIR_TOOL}"/phpMyAdmin-"${PHPMYADMIN_VERSION}"-english.zip
    mv phpMyAdmin-"${PHPMYADMIN_VERSION}"-english phpmyadmin
    rm -rf "${DEFAULT_DIR_TOOL}"/phpmyadmin/setup
    config_phpmyadmin
    cd_dir "${DIR}"

    chown -R nginx:nginx /usr/share/nginx/html "${DEFAULT_DIR_TOOL}"/phpmyadmin
    create_phpmyadmin_db
}

############################################
# Install PureFTP
############################################
install_pure_ftpd(){
    yum -y install pure-ftpd
    PURE_CONF_PATH="/etc/pure-ftpd"
    if [[ -f "${PURE_CONF_PATH}/pure-ftpd.conf" ]]; then
        mv "${PURE_CONF_PATH}"/pure-ftpd.conf "${PURE_CONF_PATH}"/pure-ftpd.conf.orig
    fi

    cat >> "${PURE_CONF_PATH}/pure-ftpd.conf" << EOpure_ftpd_conf
############################################################
#                                                          #
#             Configuration file for pure-ftpd             #
#                                                          #
############################################################
ChrootEveryone               yes
BrokenClientsCompatibility   no
MaxClientsNumber             50
Daemonize                    yes
MaxClientsPerIP              15
VerboseLog                   no
DisplayDotFiles              yes
AnonymousOnly                no
NoAnonymous                  yes
SyslogFacility               ftp
DontResolve                  yes
MaxIdleTime                  15
PureDB                       /etc/pure-ftpd/pureftpd.pdb
LimitRecursion               10000 8
AnonymousCanCreateDirs       no
MaxLoad                      4
PassivePortRange             35000 35999
AntiWarez                    yes
#Bind                        ${IPADDRESS},21
Umask                        133:022
MinUID                       99
AllowUserFXP                 yes
AllowAnonymousFXP            no
ProhibitDotFilesWrite        no
ProhibitDotFilesRead         no
AutoRename                   no
AnonymousCantUpload          no
AltLog                       stats:/var/log/pureftpd.log
PIDFile                      /run/pure-ftpd.pid
CallUploadScript             no
MaxDiskUsage                 99
CustomerProof                yes
TLS                          1
TLSCipherSuite               HIGH:MEDIUM:+TLSv1:!SSLv2:+SSLv3
CertFile                     /etc/pure-ftpd/ssl/pure-ftpd.pem
ExtCert                      /var/run/pure-certd.sock
EOpure_ftpd_conf

    mkdir -p "${PURE_CONF_PATH}"/ssl
    openssl dhparam -out "${PURE_CONF_PATH}"/ssl/pure-ftpd-dhparams.pem 2048
    openssl req -x509 -days 7300 -sha256 -nodes -subj "/C=VN/ST=Ho_Chi_Minh/L=Ho_Chi_Minh/O=Localhost/CN=${IPADDRESS}" -newkey rsa:2048 -keyout "${PURE_CONF_PATH}"/ssl/pure-ftpd.pem -out "${PURE_CONF_PATH}"/ssl/pure-ftpd.pem
    chmod 600 "${PURE_CONF_PATH}"/ssl/pure-ftpd*.pem
    touch /etc/pure-ftpd/pureftpd.passwd
    systemctl start pure-ftpd
    systemctl enable pure-ftpd
}

############################################
# Change SSH Port
############################################
change_ssh_port() {
    sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    semanage port -a -t ssh_port_t -p tcp "${SSH_PORT}"
}

############################################
# Install ACME
############################################
install_acme() {
    curl https://get.acme.sh | sh
}

############################################
# Generate htpasswd
############################################
gen_htpasswd(){
    htpasswd -b -c "${USR_DIR}"/nginx/auth/.htpasswd admin "${ADMIN_TOOL_PWD}"
}

############################################
# Opcache Dashboard
############################################
opcache_dashboard(){
    mkdir -p "${DEFAULT_DIR_TOOL}"/opcache
    wget -q "${GITHUB_RAW_LINK}"/amnuts/opcache-gui/master/index.php -O  "${DEFAULT_DIR_TOOL}"/opcache/index.php
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/opcache
    chown -R nginx:nginx "${USR_DIR}"/nginx/auth
}

############################################
# phpSysInfo
############################################
php_sys_info(){
    cd_dir "${DEFAULT_DIR_TOOL}"
    wget -q "${GITHUB_URL}"/phpsysinfo/phpsysinfo/archive/v"${PHP_SYS_INFO_VERSION}".zip
    unzip -q v"${PHP_SYS_INFO_VERSION}".zip && rm -f v"${PHP_SYS_INFO_VERSION}".zip
    mv phpsysinfo-"${PHP_SYS_INFO_VERSION}" serverinfo
    cd serverinfo && mv phpsysinfo.ini.new phpsysinfo.ini
    cd_dir "${DIR}"
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"
}

############################################
# phpmemcachedadmin
############################################
phpmemcachedadmin(){
    cd_dir "${DEFAULT_DIR_TOOL}"
    git clone https://github.com/elijaa/phpmemcachedadmin.git
    rm -rf "${DEFAULT_DIR_TOOL}"/phpmemcachedadmin/docker
    mv phpmemcachedadmin memcached
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/memcached
    cd_dir "${DIR}"
}

############################################
# Redis Admin Gui
############################################
redisdadmin(){
    cd_dir "${DEFAULT_DIR_TOOL}"
    git clone https://github.com/ErikDubbelboer/phpRedisAdmin.git
    mv phpRedisAdmin redis
    cd_dir "${DEFAULT_DIR_TOOL}"/redis
    git clone https://github.com/nrk/predis.git vendor
    cd .. && chown -R nginx:nginx redis
    cd_dir "${DIR}"
}

############################################
# Rclone
############################################
install_rclone(){
    curl https://rclone.org/install.sh | sudo bash
}

install_admin_tool(){
    gen_htpasswd
    opcache_dashboard
    php_sys_info

    if [[ "${prompt_memcached}" =~ ^([yY])$ ]]; then
        phpmemcachedadmin
    fi
    if [[ "${prompt_redis}" =~ ^([yY])$ ]]; then
        redisdadmin
    fi

    install_rclone
}

############################################
# Install CSF Firewall
############################################
csf_gui(){
    sed -i 's/UI = "0"/UI = "1"/g' /etc/csf/csf.conf
    sed -i "s/UI_PORT = \"6666\"/UI_PORT = \"${CSF_UI_PORT}\"/g" /etc/csf/csf.conf
    sed -i 's/UI_USER = "username"/UI_USER = "admin"/g' /etc/csf/csf.conf
    sed -i "s/UI_PASS = \"password\"/UI_PASS = \"${ADMIN_TOOL_PWD}\"/g" /etc/csf/csf.conf
}

install_csf(){
    yum -y install perl-Perl4-CoreLibs perl-LWP-Protocol-https perl-libwww-perl perl-GDGraph perl-IO-Socket-SSL.noarch perl-Net-SSLeay perl-Net-LibIDN perl-IO-Socket-INET6 perl-Socket6 libpng-devel
    curl -o "${DIR}"/csf.tgz https://download.configserver.com/csf.tgz
    tar -xf csf.tgz
    cd_dir "${DIR}/csf"
    sh install.sh
    cd_dir "${DIR}"
    rm -rf csf*
    if [[ "${prompt_ssh}" =~ ^([yY])$ ]]; then
        sed -i "s/21,22/21,22,${SSH_PORT}/g" /etc/csf/csf.conf
        sed -i "s/PORTS_sshd = \"22\"/PORTS_sshd = \"22,${SSH_PORT}\"/g" /etc/csf/csf.conf
    fi

    sed -i "s/993,995/993,995,9200,9300,30000:50000/g" /etc/csf/csf.conf
    sed -i "s/443,465/443,${RANDOM_ADMIN_PORT},465/g" /etc/csf/csf.conf
    sed -i "s/443,587/443,465,587,${RANDOM_ADMIN_PORT}/g" /etc/csf/csf.conf
    sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
    sed -i 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "2"/g' /etc/csf/csf.conf
    sed -i 's/CT_LIMIT = "0"/CT_LIMIT = "600"/g' /etc/csf/csf.conf
    sed -i 's/ICMP_IN = "0"/ICMP_IN = "1"/; s/ICMP_IN_RATE = "1/ICMP_IN_RATE = "5/' /etc/csf/csf.conf
    sed -i 's/PORTFLOOD = ""/PORTFLOOD = "21;tcp;20;300"/g' /etc/csf/csf.conf
    echo '#!/bin/sh' > /usr/sbin/sendmail
    chmod +x /usr/sbin/sendmail
    cat >> "/etc/csf/csf.pignore" << EOCSF
exe:/usr/sbin/nginx
exe:/usr/sbin/php-fpm
exe:/usr/sbin/rpcbind
exe:/usr/share/elasticsearch/bin/elasticsearch
exe:/usr/share/elasticsearch/modules/x-pack-ml/platform/linux-x86_64/bin/controller
cmd:/usr/share/elasticsearch/modules/x-pack-ml/platform/linux-x86_64/bin/controller
exe:/usr/share/elasticsearch/bin/systemd-entrypoint
exe:/usr/bin/pkttyagent
exe:/usr/share/elasticsearch/jdk/bin/java
exe:/usr/bin/redis-server
cmd:/usr/bin/redis-server 127.0.0.1:6379
exe:/usr/bin/rsync
exe:/usr/bin/memcached
EOCSF

    {
        echo ""
        echo "216.239.32.0/19 # Googlebot"
        echo "64.233.160.0/19 # Googlebot"
        echo "72.14.192.0/18 # Googlebot"
        echo "209.85.128.0/17 # Googlebot"
        echo "66.102.0.0/20 # Googlebot"
        echo "74.125.0.0/16 # Googlebot"
        echo "66.249.64.0/19 #Googlebot"
    } >> /etc/csf/csf.allow

    {
        echo ""
        echo ".googlebot.com"
        echo ".crawl.yahoo.net"
        echo ".search.msn.com"
        echo ".google.com"
    } >> /etc/csf/csf.rignore

    csf_gui
}

############################################
# Cronjob Update Cloudflare IP Range
############################################
cf_ip(){
    crontab -l > cloudflare
    echo "23 */36 * * * /var/hostvn/menu/cronjob/csfcf.sh >/dev/null 2>&1" >> cloudflare
    crontab cloudflare
    rm -rf cloudflare
}

############################################
# Install ClamAV
############################################

install_clamav(){
    if [ "${OS_VER}" -eq 8 ]; then
        dnf install clamav-server clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd -y
    else
        yum -y install clamav-server clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd
    fi

    setsebool -P antivirus_can_scan_system 1
    setsebool -P clamd_use_jit 1
    sed -i -e "s/^Example/#Example/" /etc/clamd.d/scan.conf
    sed -i -e "s/#LocalSocket /LocalSocket /" /etc/clamd.d/scan.conf
    sed -i -e "s/^Example/#Example/" /etc/freshclam.conf
    {
        echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.ndb"
        echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.hdb"
        echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.ldb"
        echo "DatabaseCustomURL http://cdn.malware.expert/malware.expert.fp"
    } >> /etc/freshclam.conf
}

install_av(){
    install_clamav
}

######################################
# Finished
############################################
check_service_status(){
    NGINX_STATUS="$(pgrep -f nginx)"
    if [[ -z "${NGINX_STATUS}" ]]; then
        echo "${NGINX_NOT_WORKING}" >> "${LOG}"
    fi

    MARIADB_STATUS="$(pgrep -f mariadb)"
    if [[ -z "${MARIADB_STATUS}" ]]; then
        echo "${MARIADB_NOT_WORKING}" >> "${LOG}"
    fi

    PURE_STATUS="$(pgrep -f pure-ftpd)"
    if [[ -z "${PURE_STATUS}" ]]; then
        echo "${PUREFTP_NOT_WORKING}" >> "${LOG}"
    fi

    PHP_STATUS="$(pgrep -f php-fpm)"
    if [[ -z "${PHP_STATUS}" ]]; then
        echo "${PHP_NOT_WORKING}" >> "${LOG}"
    fi

    LFD_STATUS="$(pgrep -f lfd)"
    if [[ -z "${LFD_STATUS}" ]]; then
        echo "${LFD_NOT_WORKING}" >> "${LOG}"
    fi
}

start_service() {
    systemctl enable nginx
    systemctl enable mariadb
    systemctl enable php-fpm
    systemctl start php-fpm

    csf -e
    systemctl start lfd
    systemctl enable lfd
    systemctl enable csf

    if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
        systemctl enable "${PHP_VERSION_2}"-php-fpm
        systemctl start "${PHP_VERSION_2}"-php-fpm
    fi

    cd_dir /etc/nginx/rocket-nginx
    php rocket-parser.php
    check_service_status
    setsebool -P httpd_execmem 1
}

install_wpcli_packages(){
    sed -i '/memory_limit/d' /etc/php.d/00-hostvn-custom.ini
    echo "memory_limit = -1" >> /etc/php.d/00-hostvn-custom.ini
    systemctl php-fpm restart
    wp package install iandunn/wp-cli-rename-db-prefix --allow-root
    wp package install markri/wp-sec --allow-root
    sed -i '/memory_limit/d' /etc/php.d/00-hostvn-custom.ini
    echo "memory_limit = ${MAX_MEMORY}M" >> /etc/php.d/00-hostvn-custom.ini
    systemctl php-fpm restart
}

############################################
# Create menu
############################################
add_menu(){
    cd_dir "${BASH_DIR}"
    wget "${EXT_LINK}"/menu.tar.gz  > /dev/null
    tar -xvf menu.tar.gz && rm -rf menu.tar.gz  > /dev/null
    mkdir -p "${BASH_DIR}"/users
    mkdir -p /var/log/hostvn
    mkdir -p /var/hostvn/wpcron
    chmod 711 menu users wpcron
    chmod +x ./menu/* ./menu/*/* ./menu/*/*/* ./menu/*/*/*/* > /dev/null
    dos2unix ./menu/* > /dev/null
    dos2unix ./menu/*/* > /dev/null
    dos2unix ./menu/*/*/* > /dev/null

    mv "${BASH_DIR}"/menu/hostvn /usr/bin/hostvn && chmod +x /usr/bin/hostvn

    sed -i "s/IPADDRESS/#IPADDRESS/g" "${BASH_DIR}"/menu/helpers/variable_common

    {
        echo ""
        echo "IPADDRESS=${IPADDRESS}"
    } >> "${BASH_DIR}"/menu/helpers/variable_common

    if [[ ! -f "/var/hostvn/ipaddress" ]]; then
        cat >> "/var/hostvn/ipaddress" << END
#!/bin/bash
IPADDRESS=${IPADDRESS}
END
    fi
}

############################################
# Write Info
############################################
write_info(){
    touch "${FILE_INFO}"
    {
        echo "script_version=${SCRIPTS_VERSION}"
        echo "ssh_port=${SSH_PORT}"
        echo "admin_port=${RANDOM_ADMIN_PORT}"
        echo "csf_port=${CSF_UI_PORT}"
        echo "ftp_port=21"
        echo "admin_pwd=${ADMIN_TOOL_PWD}"
        echo "mysql_pwd=${SQLPASS}"
        echo "admin_email=${ADMIN_EMAIL}"
        echo "php1_release=yes"
        echo "php2_release=${PHP2_RELEASE}"
        echo "php1_version=${PHP_VERSION}"
        echo "php2_version=${PHP_VERSION_2}"
        echo "lang=vi"
    } >> "${FILE_INFO}"

    touch /etc/hostvn.lock
    chmod 600 "${FILE_INFO}" /etc/hostvn.lock
}

############################################
# Run Script
############################################
# Prepare before install
create_bash_dir
config_selinux
set_timezone
set_os_arch
create_log
set_email

# Select options
input_ip
select_php_ver
select_php_multi

if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
    select_php_ver_2
    check_duplicate_php
fi

option_clamav
option_memcached
option_redis
option_pureftp
option_change_ssh_port

# Install
install_nginx

if [[ ! -f "/usr/lib/systemd/system/nginx.service" ]]; then
    clear
    printf "%s\n" "${INST_NGINX_ERR}"
    sleep 3
    exit
fi

nginx_brotli
# install_naxsi
install_mariadb

if [[ ! -f "/usr/lib/systemd/system/mariadb.service" ]]; then
    clear
    printf "%s\n" "${INST_MARIADB_ERR}"
    sleep 3
    exit
fi

install_php

if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
    install_php_2

    if [[ ! -f "/usr/lib/systemd/system/${PHP_VERSION_2}-php-fpm.service" ]]; then
        clear
        PHP2_RELEASE="no"
        printf "%s\n" "${INST_PHP_ERR_2}"
        sleep 3
    fi
fi

if [[ ! -f "/usr/lib/systemd/system/php-fpm.service" ]]; then
    clear
    printf "%s\n" "${INST_PHP_ERR}"
    sleep 3
    exit
fi

if [[ ! -f "/usr/lib/systemd/system/php-fpm.service" ]]; then
    clear
    printf "%s\n" "${INST_PHP_ERR}"
    sleep 3
    exit
fi
install_composer
install_wpcli
memory_calculation
if [[ "${prompt_memcached}" =~ ^([yY])$ ]]; then
    install_memcached
fi

if [[ "${prompt_redis}" =~ ^([yY])$ ]]; then
    install_redis
fi

install_igbinary

if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
    install_igbinary_2
fi

if [[ -f "${PHP_MODULES_DIR}/igbinary.so" ]]; then
    install_php_memcached
    install_php_redis
fi

if [[ -f "${PHP_MODULES_DIR_2}/igbinary.so" ]]; then
    install_php_memcached_2
    install_php_redis_2
fi

# Config
self_signed_ssl
cal_ssl_cache_size
create_nginx_conf
create_extra_conf
create_wp_cache_conf
vhost_custom
default_vhost
default_index
default_error_page
wprocket_nginx
php_global_config
hostvn_custom_ini
php_opcache

if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
    php_global_config_2
    hostvn_custom_ini_2
    php_opcache_2
fi
config_my_cnf
set_mariadb_root_pwd
create_mysql_user
limits_config
sysctl_config
log_rotation

# Install other tool
install_phpmyadmin

if [[ "${prompt_pureftpd}" =~ ^([yY])$ ]]; then
    install_pure_ftpd
fi

install_acme
install_csf
install_admin_tool
cf_ip

if [[ "${prompt_inst_av}" =~ ^([yY])$ ]]; then
    install_av
fi

#Fix phpmyadmin error /var/lib/php/session
chown -R nginx. /var/lib/php/session
chmod 0755 /var/lib/php/session

# End install
add_menu
start_service
write_info
ssh_login_noti

if [[ "${prompt_ssh}" =~ ^([yY])$ ]]; then
    change_ssh_port
fi

clear
sleep 1

printf "=========================================================================\n"
printf "                              Cai dat thanh cong                         \n"
printf "                 File luu thong tin: %s\n" "${FILE_INFO}"
printf "          Neu can ho tro vui long truy cap %s\n" "${AUTHOR_CONTACT}"
printf "==========================================================================\n"
printf "              Luu lai thong tin duoi day de truy cap SSH va phpMyAdmin    \n"
printf "                  ${RED}%s${NC}           \n" "De mo Menu su dung lenh: hostvn"
printf "==========================================================================\n"
printf "SSH  Port                    : %s\n" "${SSH_PORT}"
printf "phpMyAdmin                   : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/phpmyadmin"
printf "Link Opcache Dashboard       : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/opcache"
printf "Link Server Info             : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/serverinfo"
if [[ "${prompt_memcached}" =~ ^([yY])$ ]]; then
printf "Link php Memcached Admin     : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/memcached"
fi
if [[ "${prompt_redis}" =~ ^([yY])$ ]]; then
printf "Link Redis Admin             : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/redis"
fi
printf "Link CSF GUI                 : %s\n" "https://${IPADDRESS}:${CSF_UI_PORT}"
echo   "User phpMyAdmin va Admin Tool: admin                                   "
printf "Password Admin tool          : %s\n" "${ADMIN_TOOL_PWD}"
printf "Password phpMyAdmin          : %s\n" "${SQLPASS}"
printf "=========================================================================\n"

sleep 3
shutdown -r now
