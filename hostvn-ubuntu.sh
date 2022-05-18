#!/bin/bash

######################################################################
#           Auto Install & Optimize LEMP Stack on Ubuntu             #
#                                                                    #
#                Author: Sanvv - HOSTVN Technical                    #
#                  Website: https://hostvn.vn                        #
#                                                                    #
#              Please do not remove copyright. Thank!                #
#  Please do not copy under any circumstance for commercial reason!  #
######################################################################

# shellcheck disable=SC2207

apt update && apt upgrade -y

DIR=$(pwd)

# Set Color
RED='\033[0;31m'
NC='\033[0m'

SCRIPTS_VERSION="0.2.9"
IPADDRESS=$(curl -s http://cyberpanel.sh/?ip)
DIR=$(pwd)
BASH_DIR="/var/hostvn"
GITHUB_RAW_LINK="https://raw.githubusercontent.com"
EXT_LINK="https://scripts.hostvn.net"
UPDATE_LINK="https://scripts.hostvn.net/ubuntu/update"
FILE_INFO="${BASH_DIR}/.hostvn.conf"
HOSTNAME=$(hostname)
PHP2_RELEASE="no"

# Copyright
AUTHOR="HOSTVN.VN"
AUTHOR_CONTACT="https://www.facebook.com/groups/hostvn.vn"

# Service Version
PHPMYADMIN_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "phpmyadmin_version=" | cut -f2 -d'=')
MARIADB_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "mariadb_version=" | cut -f2 -d'=')
# shellcheck disable=SC2207
PHP_LIST=($(curl -s http://scripts.hostvn.net/ubuntu/update/version | grep "php_list=" | cut -f2 -d'='))

# Set Lang
OPTION_CHANGE_SSH="Ban co muon thay doi port SSH khong ? "
ENTER_OPTION="Nhap vao lua chon cua ban: "
SELECT_PHP="Hay lua chon phien ban PHP muon cai dat:"
WRONG_PHP_OPTION="Lua chon cua ban khong chinh xac, vui long chon lai."
SELECT_INST_PHP_2="Ban co muon cai dat phien ban PHP thu hai khong - Multiple PHP ?"
ENTER_OPTION_PHP_2="Nhap vao lua chon cua ban [1-2]: "
WRONG_PHP_SELECT_2="Ban nhap sai. Vui long nhap lai."
INVALID_PHP2_OPTION="${RED}Lua chon cua ban khong chinh xac. Vui long chon lai.${NC}"
SELECT_PHP_2="Lua chon phien ban PHP thu hai ban muon su dung:"
LOGIN_NOTI1="Cam on ban da su dung dich vu cua ${AUTHOR}."
LOGIN_NOTI2="Neu can ho tro vui long truy cap ${AUTHOR_CONTACT}"
LOGIN_NOTI3="Truoc khi dat cau hoi vui long xem Document: https://doc.hostvn.vn/"
LOGIN_NOTI4="De mo menu ban go lenh sau:  hostvn"

# Random Port
RANDOM_ADMIN_PORT=$(shuf -i 49152-57343 -n 1)

# Dir
DEFAULT_DIR_WEB="/usr/share/nginx/html"
DEFAULT_DIR_TOOL="/usr/share/nginx/private"
USR_DIR="/usr/share"

# Get info VPS
CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
RAM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
SWAP_TOTAL=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
PHP_MEM=${RAM_TOTAL}+${SWAP_TOTAL}
MAX_CLIENT=$((CPU_CORES * 1024))

rm -rf "${DIR}"/hostvn

############################################
# Function
############################################
cd_dir() {
    cd "$1" || return
}

gen_pass() {
    PASS_LEN=$(perl -le 'print int(rand(6))+9')
    START_LEN=$(perl -le 'print int(rand(8))+1')
    END_LEN=$((PASS_LEN - START_LEN))
    NUMERIC_CHAR=$(perl -le 'print int(rand(10))')
    PASS_START=$(perl -le "print map+(A..Z,a..z,0..9)[rand 62],0..$START_LEN")
    PASS_END=$(perl -le "print map+(A..Z,a..z,0..9)[rand 62],0..$END_LEN")
    PASS=${PASS_START}${NUMERIC_CHAR}${PASS_END}
    echo "$PASS"
}

random_string() {
    STRING=$(perl -le "print map+(A..Z,a..z,0..9)[rand 62],0..$1")
    echo "$STRING"
}

valid_ip() {
    # shellcheck disable=SC2166
    if [ -n "$1" -a -z "${*##*\.*}" ]; then
        ipcalc "$1" |
            awk 'BEGIN{FS=":";is_invalid=0} /^INVALID/ {is_invalid=1; print $1} END{exit is_invalid}'
    else
        return 1
    fi
}

############################################
# Prepare install
############################################
create_bash_dir() {
    mkdir -p /home/backup
    chmod 710 /home/backup
    chmod 711 /home
    mkdir -p "${BASH_DIR}"
    mkdir -p "${BASH_DIR}"/custom
}

# Admin Email
set_email() {
    clear
    while true; do
        read -r -p "Nhap vao email cua ban: " ADMIN_EMAIL
        echo
        if [[ "${ADMIN_EMAIL}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
            echo "Email cua ban la: ${ADMIN_EMAIL}."
            break
        else
            echo "Email ban nhap khong chinh xac vui long nhap lai."
        fi
    done
}

ssh_login_notify() {
    string=$(grep -rnw "$HOME/.bashrc" -e "${AUTHOR}")
    if [ -z "${string}" ]; then
        {
            echo "echo \"${LOGIN_NOTI1}\""
            echo "echo \"${LOGIN_NOTI2}\""
            echo "echo \"${LOGIN_NOTI3}\""
            echo "echo \"${LOGIN_NOTI4}\""
        } >>"$HOME"/.bashrc
    fi
}

############################################
# Option Install
############################################
input_ip() {
    echo "Nhap vao dia chi IP cua VPS. Bam Enter de script tu detect IP Public."
    read -r -p "Nhap vao dia chi IP cua VPS: " IPADDRESS_NEW
    if [ -n "${IPADDRESS_NEW}" ] && valid_ip "${IPADDRESS_NEW}"; then
        IPADDRESS=${IPADDRESS_NEW}
    else
        printf "IP ban nhap khong chinh xac. Script se tu dong detect IP Public cua VPS."
    fi
}

option_change_ssh_port() {
    clear
    printf "%s\n" "${OPTION_CHANGE_SSH}"
    PS3="${ENTER_OPTION}"
    options=("Yes" "No")
    select opt in "${options[@]}"; do
        case $opt in
        "Yes")
            prompt_ssh="y"
            SSH_PORT="8282"
            sleep 1
            printf "${RED}%s${NC}\n" "Port SSH moi là: 8282"
            printf "${RED}%s${NC}\n" "Luu y: Voi Google Cloud, Alibaba Cloud, AWS cac ban can mo port 8282 trong tab Firewall"
            sleep 1
            break
            ;;
        "No")
            prompt_ssh="n"
            SSH_PORT="22"
            break
            ;;
        *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY" ;;
        esac
    done
    sleep 1
}

select_php_ver() {
    clear
    while true; do
        printf "%s\n" "${SELECT_PHP}"
        PS3="${ENTER_OPTION}"
        select opt in "${PHP_LIST[@]}"; do
            case $opt in
            "$opt")
                PHP_VERSION="${opt}"
                break
                ;;
            esac
        done
        echo

        if [[ " ${PHP_LIST[*]} " == *" ${PHP_VERSION} "* ]]; then
            break
        else
            clear
            printf "${RED}%s${NC}\n" "${WRONG_PHP_OPTION}"
        fi
    done
    sleep 1

    PHP_VERSION=${PHP_VERSION//php/}
    PHP1_CONFIG_PATH="/etc/php/${PHP_VERSION}/fpm"
    PHP1_INI_PATH="${PHP1_CONFIG_PATH}/conf.d"
    PHP1_POOL_PATH="${PHP1_CONFIG_PATH}/pool.d"
    PHP1_CLI_PATH="/etc/php/${PHP_VERSION}/cli/conf.d"
}

select_php_multi() {
    clear
    printf "%s\n" "${SELECT_INST_PHP_2}"
    PS3="${ENTER_OPTION_PHP_2}"
    options=("Yes" "No")
    select opt in "${options[@]}"; do
        case $opt in
        "Yes")
            MULTI_PHP="y"
            break
            ;;
        "No")
            MULTI_PHP="n"
            break
            ;;
        *) printf "${RED}%s${NC}\n" "${WRONG_PHP_SELECT_2} $REPLY" ;;
        esac
    done
    sleep 1
}

select_php_ver_2() {
    clear
    while true; do
        printf "%s\n" "${SELECT_PHP_2}"
        PS3="${ENTER_OPTION}"
        select opt in "${PHP_LIST[@]}"; do
            case $opt in
            "$opt")
                PHP_VERSION_2="${opt}"
                break
                ;;
            esac
        done
        echo

        if [[ " ${PHP_LIST[*]} " == *" ${PHP_VERSION_2} "* ]]; then
            break
        else
            clear
            printf "${RED}%s\n${NC}" "${INVALID_PHP2_OPTION}"
        fi
    done

    PHP_VERSION_2=${PHP_VERSION_2//php/}
    PHP2_CONFIG_PATH="/etc/php/${PHP_VERSION_2}/fpm"
    PHP2_INI_PATH="${PHP2_CONFIG_PATH}/conf.d"
    PHP2_POOL_PATH="${PHP2_CONFIG_PATH}/pool.d"
    PHP2_CLI_PATH="/etc/php/${PHP_VERSION_2}/cli/conf.d"
    sleep 1
}

check_duplicate_php() {
    if [[ "${PHP_VERSION_2}" == "${PHP_VERSION}" ]]; then
        MULTI_PHP="n"
        echo "Phien ban PHP thứ 2 trung voi phien ban mac dinh. He thong se cai dat mot phien ban PHP."
    fi
}

############################################
# Install LEMP Stack
############################################
#install_nginx() {
#    apt-get install -y curl gnupg2 ca-certificates lsb-release
#    apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev -y
#    apt-get install -y git build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev \
#        libcurl4-openssl-dev automake pkgconf -y
#    apt autoremove -y
#    # shellcheck disable=SC2006
#    echo "deb http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" |
#        tee /etc/apt/sources.list.d/nginx.list
#    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
#    apt-key fingerprint ABF5BD827BD9BF62
#    apt-get -y update
#    apt-get -y install nginx
#
#    systemctl start nginx
#    systemctl enable nginx
#}

#install_nginx(){
#    apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev -y
#    apt autoremove -y
#    UPDATE_LINK="https://scripts.hostvn.net/update"
#    MODULE_PATH="/usr/share/nginx_module"
#    mkdir -p "${MODULE_PATH}"
#    NGINX_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "nginx_version=" | cut -f2 -d'=')
#    NPS_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "nps_version=" | cut -f2 -d'=')
#    ngx_cache_purge_version=$(curl -s ${UPDATE_LINK}/version | grep "ngx_cache_purge_version=" | cut -f2 -d'=')
#    openssl_version=$(curl -s ${UPDATE_LINK}/version | grep "openssl_version=" | cut -f2 -d'=')
#    pcre_version=$(curl -s ${UPDATE_LINK}/version | grep "pcre_version=" | cut -f2 -d'=')
#    zlib_version=$(curl -s ${UPDATE_LINK}/version | grep "zlib_version=" | cut -f2 -d'=')
#
#    cd_dir "${MODULE_PATH}"
#
#    wget -O- https://github.com/apache/incubator-pagespeed-ngx/archive/v"${NPS_VERSION}".tar.gz | tar -xz
#    nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d)
#    cd_dir "$nps_dir"
#    NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
#    NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
#
#    psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
#    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
#    wget -O- "${psol_url}" | tar -xz
#
#    cd_dir "${MODULE_PATH}"
#    wget -O- http://nginx.org/download/nginx-"${NGINX_VERSION}".tar.gz | tar -xz
#    wget -O- http://scripts.hostvn.net/ubuntu/ngx_cache_purge-"${ngx_cache_purge_version}".tar.gz | tar -xz
#    wget -O- http://scripts.hostvn.net/ubuntu/openssl-OpenSSL_"${openssl_version}".tar.gz | tar -xz
#    wget -O- ftp://ftp.pcre.org/pub/pcre/pcre-"${pcre_version}".tar.gz | tar -xz
#    wget -O- https://www.zlib.net/zlib-"${zlib_version}".tar.gz | tar -xz
#    git clone --depth 1 https://github.com/google/ngx_brotli
#    cd_dir ngx_brotli && git submodule update --init
#
#    apt-get install -y git build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev \
#        libcurl4-openssl-dev automake pkgconf
#    apt-get install bison build-essential ca-certificates curl dh-autoreconf doxygen flex gawk git iputils-ping \
#        libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev libpcre3-dev libpcre++-dev libssl-dev libtool \
#        libxml2 libxml2-dev libyajl-dev locales lua5.3-dev pkg-config wget zlib1g-dev -y
#    apt autoremove -y
#
#    cd_dir "${MODULE_PATH}"
#    git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git
#    #wget -O- http://scripts.hostvn.net/ubuntu/ModSecurity.tar.gz | tar -xz
#    cd_dir ModSecurity
#    ./autogen.sh
#    ./configure --enable-standalone-module --disable-mlogc
#    make
#    cd_dir "${MODULE_PATH}"/nginx-"${NGINX_VERSION}"/
#    ./configure \
#        "--user=nginx" \
#        "--group=nginx" \
#        "--prefix=/usr" \
#        "--sbin-path=/usr/sbin" \
#        "--conf-path=/etc/nginx/nginx.conf" \
#        "--pid-path=/var/run/nginx.pid" \
#        "--http-log-path=/var/log/nginx/access_log" \
#        "--error-log-path=/var/log/nginx/error_log" \
#        "--without-mail_imap_module" \
#        "--without-mail_smtp_module" \
#        "--with-http_ssl_module" \
#        "--with-http_realip_module" \
#        "--with-http_stub_status_module" \
#        "--with-http_gzip_static_module" \
#        "--with-http_dav_module" \
#        "--with-http_v2_module" \
#        "--with-pcre=../pcre-${pcre_version}" \
#        "--with-pcre-jit" \
#        "--with-zlib=../zlib-${zlib_version}" \
#        "--with-openssl=../openssl-OpenSSL_${openssl_version}" \
#        "--with-openssl-opt=no-nextprotoneg" \
#        "--add-module=../ngx_cache_purge-${ngx_cache_purge_version}" \
#        "--add-module=../incubator-pagespeed-ngx-${NPS_VERSION}" \
#        "--add-module=../ngx_brotli" \
#        "--add-module=../ModSecurity/nginx/modsecurity" \
#        "--with-cc-opt='-D FD_SETSIZE=32768'"
#
#    make && make install
#
#    if [[ -d "/usr/lib/nginx/modules" && ! -d "/etc/nginx/modules" ]]; then
#        ln -s /usr/lib/nginx/modules /etc/nginx/modules
#    fi
#
#    adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password \
#        --gecos "nginx user" --group nginx
#
#    if [ ! -f "/etc/systemd/system/nginx.service" ]; then
#        cat >> "/etc/systemd/system/nginx.service" << EOnginx_service
#[Unit]
#Description=The nginx HTTP and reverse proxy server
#After=syslog.target network.target remote-fs.target nss-lookup.target
#
#[Service]
#Type=forking
#PIDFile=/var/run/nginx.pid
#ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
#ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
#ExecReload=/bin/kill -s HUP \$MAINPID
#ExecStop=/bin/kill -s QUIT \$MAINPID
#PrivateTmp=true
#LimitMEMLOCK=infinity
#LimitNOFILE=65535
#
#[Install]
#WantedBy=multi-user.target
#EOnginx_service
#    fi
#
#    sudo systemctl enable nginx.service
#    sudo systemctl start nginx.service
#    cd_dir "${DIR}"
#}

install_nginx(){
    apt-get install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev -y
    apt autoremove -y
    UPDATE_LINK="http://scripts.hostvn.net/ubuntu/update"
    MODULE_PATH="/usr/share/nginx_module"
    mkdir -p "${MODULE_PATH}"
    NGINX_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "nginx_version=" | cut -f2 -d'=')
    NPS_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "nps_version=" | cut -f2 -d'=')
    ngx_cache_purge_version=$(curl -s ${UPDATE_LINK}/version | grep "ngx_cache_purge_version=" | cut -f2 -d'=')
    more_clear_headers_v=$(curl -s ${UPDATE_LINK}/version | grep "more_clear_headers_v=" | cut -f2 -d'=')
    openssl_version=$(curl -s ${UPDATE_LINK}/version | grep "openssl_version=" | cut -f2 -d'=')
    pcre_version=$(curl -s ${UPDATE_LINK}/version | grep "pcre_version=" | cut -f2 -d'=')
    zlib_version=$(curl -s ${UPDATE_LINK}/version | grep "zlib_version=" | cut -f2 -d'=')
    nginx_module_vts_v=$(curl -s ${UPDATE_LINK}/version | grep "nginx_module_vts_v=" | cut -f2 -d'=')

    cd_dir "${MODULE_PATH}"

    wget -O- https://github.com/apache/incubator-pagespeed-ngx/archive/v"${NPS_VERSION}".tar.gz | tar -xz
    nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d)
    cd_dir "$nps_dir"
    NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
    NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}

    psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
    wget -O- "${psol_url}" | tar -xz

    cd_dir "${MODULE_PATH}"
    wget -O- http://nginx.org/download/nginx-"${NGINX_VERSION}".tar.gz | tar -xz
    wget -O- http://scripts.hostvn.net/ubuntu/modules/ngx_cache_purge-"${ngx_cache_purge_version}".tar.gz | tar -xz
    wget -O- http://scripts.hostvn.net/ubuntu/modules/openssl-OpenSSL_"${openssl_version}".tar.gz | tar -xz
    wget -O- http://scripts.hostvn.net/ubuntu/modules/pcre-"${pcre_version}".tar.gz | tar -xz
    wget -O- http://scripts.hostvn.net/ubuntu/modules/zlib-"${zlib_version}".tar.gz | tar -xz
    wget -O- http://scripts.hostvn.net/ubuntu/modules/headers-more-nginx-module-"${more_clear_headers_v}".tar.gz | tar -xz
    wget -O- https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v"${nginx_module_vts_v}".tar.gz | tar -xz

    git clone --depth 1 https://github.com/google/ngx_brotli
    cd_dir ngx_brotli && git submodule update --init

    cd_dir "${MODULE_PATH}"/nginx-"${NGINX_VERSION}"/
    ./configure \
        "--user=nginx" \
        "--group=nginx" \
        "--prefix=/usr" \
        "--sbin-path=/usr/sbin" \
        "--conf-path=/etc/nginx/nginx.conf" \
        "--pid-path=/var/run/nginx.pid" \
        "--http-log-path=/var/log/nginx/access_log" \
        "--error-log-path=/var/log/nginx/error_log" \
        "--without-mail_imap_module" \
        "--without-mail_smtp_module" \
        "--with-http_ssl_module" \
        "--with-http_realip_module" \
        "--with-http_stub_status_module" \
        "--with-http_gzip_static_module" \
        "--with-http_dav_module" \
        "--with-http_v2_module" \
        "--with-pcre=../pcre-${pcre_version}" \
        "--with-pcre-jit" \
        "--with-zlib=../zlib-${zlib_version}" \
        "--with-openssl=../openssl-OpenSSL_${openssl_version}" \
        "--with-openssl-opt=no-nextprotoneg" \
        "--add-module=../ngx_cache_purge-${ngx_cache_purge_version}" \
        "--add-module=../incubator-pagespeed-ngx-${NPS_VERSION}" \
        "--add-module=../headers-more-nginx-module-${more_clear_headers_v}" \
        "--add-module=../ngx_brotli" \
        "--add-module=../nginx-module-vts-${nginx_module_vts_v}" \
        "--with-cc-opt='-D FD_SETSIZE=32768'"

    make && make install

    if [[ -d "/usr/lib/nginx/modules" && ! -d "/etc/nginx/modules" ]]; then
        ln -s /usr/lib/nginx/modules /etc/nginx/modules
    fi

    adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password \
        --gecos "nginx user" --group nginx

    rm -rf /etc/systemd/system/nginx.service
    cat >> "/etc/systemd/system/nginx.service" << EOnginx_service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
LimitMEMLOCK=infinity
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOnginx_service

    sudo systemctl enable nginx.service
    sudo systemctl start nginx.service
    cd_dir "${DIR}"
}

install_mariadb() {
    apt-get install software-properties-common apt-transport-https -y
#    apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' << EOF
#
#EOF
#    add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://sgp1.mirrors.digitalocean.com/mariadb/repo/${MARIADB_VERSION}/ubuntu $(lsb_release -cs) main" << EOF
#
#EOF

    wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    echo "b7519209546e1656e5514c04b4dcffdd9b4123201bcd1875a361ad79eb943bbe mariadb_repo_setup" | sha256sum -c -
    chmod +x mariadb_repo_setup
    ./mariadb_repo_setup --mariadb-server-version="mariadb-${MARIADB_VERSION}"
    apt-get update -y
    apt-get -y install mariadb-server mariadb-backup
}

install_php() {
    add-apt-repository ppa:ondrej/php <<EOF

EOF

    apt-get update -y

    apt-get -y install php"${PHP_VERSION}" php"${PHP_VERSION}"-fpm php"${PHP_VERSION}"-ldap php"${PHP_VERSION}"-zip \
        php"${PHP_VERSION}"-cli php"${PHP_VERSION}"-mysql php"${PHP_VERSION}"-gd php"${PHP_VERSION}"-xml \
        php"${PHP_VERSION}"-mbstring php"${PHP_VERSION}"-common php"${PHP_VERSION}"-soap \
        php"${PHP_VERSION}"-curl php"${PHP_VERSION}"-bcmath php"${PHP_VERSION}"-snmp php"${PHP_VERSION}"-pspell \
        php"${PHP_VERSION}"-gmp php"${PHP_VERSION}"-intl php"${PHP_VERSION}"-imap php"${PHP_VERSION}"-enchant \
        php"${PHP_VERSION}"-xmlrpc php"${PHP_VERSION}"-tidy php"${PHP_VERSION}"-opcache php"${PHP_VERSION}"-cli \
        php"${PHP_VERSION}"-dev php"${PHP_VERSION}"-imagick php"${PHP_VERSION}"-sqlite3

    if [ "${PHP_VERSION}" != "8.0" ]; then
        apt -y install php"${PHP_VERSION}"-json
    fi

    if [ "${PHP_VERSION}" == "5.6" ]; then
        apt -y install php5.6-mcrypt
    fi

    if [ -f "/usr/lib/systemd/system/php${PHP_VERSION}-fpm.service" ]; then
        sed -i '/ExecReload=/a LimitNOFILE=65535' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ExecReload=/a LimitMEMLOCK=infinity' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/LimitNOFILE=65535/a PrivateTmp=true' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/PrivateTmp=true/a ProtectKernelModules=true' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ProtectKernelModules=true/a ProtectKernelTunables=true' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ProtectKernelTunables=true/a ProtectControlGroups=true' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ProtectControlGroups=true/a RestrictRealtime=true' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/RestrictRealtime=true/a RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX' /usr/lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        systemctl daemon-reload
    fi

    if [[ -f "/lib/systemd/system/php${PHP_VERSION}-fpm.service" && ! -f "/usr/lib/systemd/system/php${PHP_VERSION}-fpm.service" ]]; then
        sed -i '/ExecReload=/a LimitNOFILE=65535' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ExecReload=/a LimitMEMLOCK=infinity' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/LimitNOFILE=65535/a PrivateTmp=true' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/PrivateTmp=true/a ProtectKernelModules=true' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ProtectKernelModules=true/a ProtectKernelTunables=true' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ProtectKernelTunables=true/a ProtectControlGroups=true' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/ProtectControlGroups=true/a RestrictRealtime=true' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        sed -i '/RestrictRealtime=true/a RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX' /lib/systemd/system/php"${PHP_VERSION}"-fpm.service
        systemctl daemon-reload
    fi

    update-alternatives --set php /usr/bin/php"${PHP_VERSION}"
}

install_php_2() {
    apt-get -y install php"${PHP_VERSION_2}" php"${PHP_VERSION_2}"-fpm php"${PHP_VERSION_2}"-ldap php"${PHP_VERSION_2}"-zip \
        php"${PHP_VERSION_2}"-cli php"${PHP_VERSION_2}"-mysql php"${PHP_VERSION_2}"-gd php"${PHP_VERSION_2}"-xml \
        php"${PHP_VERSION_2}"-mbstring php"${PHP_VERSION_2}"-common php"${PHP_VERSION_2}"-soap \
        php"${PHP_VERSION_2}"-curl php"${PHP_VERSION_2}"-bcmath php"${PHP_VERSION_2}"-snmp php"${PHP_VERSION_2}"-pspell \
        php"${PHP_VERSION_2}"-gmp php"${PHP_VERSION_2}"-intl php"${PHP_VERSION_2}"-imap php"${PHP_VERSION_2}"-enchant \
        php"${PHP_VERSION_2}"-xmlrpc php"${PHP_VERSION_2}"-tidy php"${PHP_VERSION_2}"-opcache php"${PHP_VERSION_2}"-cli \
        php"${PHP_VERSION_2}"-dev php"${PHP_VERSION_2}"-imagick php"${PHP_VERSION_2}"-sqlite3

    if [ "${PHP_VERSION_2}" != "8.0" ]; then
        apt -y install php"${PHP_VERSION_2}"-json
    fi

    if [ "${PHP_VERSION_2}" == "5.6" ]; then
        apt -y install php5.6-mcrypt
    fi

    PHP2_RELEASE="yes"
    if [ -f "/usr/lib/systemd/system/php${PHP_VERSION_2}-fpm.service" ]; then
        sed -i '/ExecReload=/a LimitNOFILE=65535' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ExecReload=/a LimitMEMLOCK=infinity' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/LimitNOFILE=65535/a PrivateTmp=true' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/PrivateTmp=true/a ProtectKernelModules=true' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ProtectKernelModules=true/a ProtectKernelTunables=true' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ProtectKernelTunables=true/a ProtectControlGroups=true' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ProtectControlGroups=true/a RestrictRealtime=true' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/RestrictRealtime=true/a RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX' /usr/lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        systemctl daemon-reload
    fi

    if [[ -f "/lib/systemd/system/php${PHP_VERSION_2}-fpm.service" && ! -f "/usr/lib/systemd/system/php${PHP_VERSION_2}-fpm.service" ]]; then
        sed -i '/ExecReload=/a LimitNOFILE=65535' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ExecReload=/a LimitMEMLOCK=infinity' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/LimitNOFILE=65535/a PrivateTmp=true' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/PrivateTmp=true/a ProtectKernelModules=true' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ProtectKernelModules=true/a ProtectKernelTunables=true' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ProtectKernelTunables=true/a ProtectControlGroups=true' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/ProtectControlGroups=true/a RestrictRealtime=true' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        sed -i '/RestrictRealtime=true/a RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX' /lib/systemd/system/php"${PHP_VERSION_2}"-fpm.service
        systemctl daemon-reload
    fi
}

install_phpmyadmin() {
    if [ "${PHP_VERSION}" == "5.6" ]; then
        PHPMYADMIN_VERSION=$(curl -s ${UPDATE_LINK}/version | grep "phpmyadmin4_version=" | cut -f2 -d'=')
    fi

    if [ "${PHP_VERSION}" != "5.6" ]; then
        DECLARE="declare(strict_types=1);"
    fi
    if [ -f "${DEFAULT_DIR_TOOL}" ]; then
        rm -rf "${DEFAULT_DIR_TOOL}"
    fi
    if [ ! -d "${DEFAULT_DIR_TOOL}" ]; then
        mkdir -p "${DEFAULT_DIR_TOOL}"
    fi
    cd_dir "${DEFAULT_DIR_TOOL}"

    wget -O- http://scripts.hostvn.net/modules/phpMyAdmin-"${PHPMYADMIN_VERSION}"-english.tar.gz | tar -xz

    mv phpMyAdmin-"${PHPMYADMIN_VERSION}"-english phpmyadmin
    rm -rf phpMyAdmin-"${PHPMYADMIN_VERSION}"-english.zip
    rm -rf "${DEFAULT_DIR_TOOL}"/phpmyadmin/setup

    mv "${DEFAULT_DIR_TOOL}"/phpmyadmin/config.sample.inc.php "${DEFAULT_DIR_TOOL}"/phpmyadmin/config.inc.php

    BLOWFISH_SECRET=$(random_string 64)
    mkdir -p "${DEFAULT_DIR_TOOL}"/phpmyadmin/tmp

    cat >"${DEFAULT_DIR_TOOL}/phpmyadmin/config.inc.php" <<EOCONFIGINC
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
\$cfg['DefaultCharset'] = 'utf8';
\$cfg['DefaultConnectionCollation'] = 'utf8_general_ci';
EOCONFIGINC

    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/phpmyadmin
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/phpmyadmin

    cat >> "/opt/phpmyadmin.temp" <<EOphpmyadmin_temp
CREATE DATABASE IF NOT EXISTS phpmyadmin;
FLUSH PRIVILEGES;
EOphpmyadmin_temp

    mysql -u root -p"${sql_root_pass}" < /opt/phpmyadmin.temp
    rm -f /opt/phpmyadmin.temp

    curl -o phpmyadmin.sql "${EXT_LINK}"/phpmyadmin.sql
    mysql -u root -p"${sql_root_pass}" phpmyadmin < phpmyadmin.sql
    rm -rf phpmyadmin.sql
}

############################################
# Install Composer
############################################
install_composer() {
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    # Composer 1
    wget https://getcomposer.org/download/1.10.20/composer.phar
    mv composer.phar /usr/local/bin/composer1
    chmod +x /usr/local/bin/composer1
}

############################################
# Install WP-CLI
############################################
install_wp_cli() {
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
}

############################################
# Dynamic calculation
############################################
php_memory_calculation() {
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

cal_ssl_cache_size() {
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

php_parameter() {
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

mariadb_calculation() {
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

    if [[ "$(expr "${RAM_TOTAL}" \>= 33586432)" == "1" ]]; then #32GB Ram
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

    if [[ "$(expr "${RAM_TOTAL}" \>= 64000000)" == "1" ]]; then #64GB Ram
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

############################################
# Install Other Library
############################################
install_optipng(){
    optipng_version=$(curl -s ${UPDATE_LINK}/version | grep "optipng_version=" | cut -f2 -d'=')
    cd_dir /opt
    wget -O- http://scripts.hostvn.net/modules/optipng-"${optipng_version}".tar.gz | tar -xz
    cd_dir optipng-"${optipng_version}"
    ./configure
    make
    cp /opt/optipng-"${optipng_version}"/src/optipng/optipng /usr/bin/
    cd_dir /opt
    rm -rf /opt/optipng-"${optipng_version}"
}

install_jpegoptim(){
    jpegoptim_version=$(curl -s ${UPDATE_LINK}/version | grep "jpegoptim_version=" | cut -f2 -d'=')
    cd_dir /opt
    wget -O- http://scripts.hostvn.net/modules/jpegoptim-RELEASE."${jpegoptim_version}".tar.gz | tar -xz
    cd_dir jpegoptim-RELEASE."${jpegoptim_version}"
    ./configure
    make && make strip && make install
    ln -s /usr/local/bin/jpegoptim /usr/bin/jpegoptim
    cd_dir /opt
    rm -rf /opt/jpegoptim-RELEASE."${jpegoptim_version}"
}

install_pngquant(){
    cd_dir /opt
    git clone --recursive https://github.com/kornelski/pngquant.git
    cd_dir /opt/pngquant
    ./configure
    make && make install
    cd_dir "${DIR}"
    rm -rf /opt/pngquant
}

############################################
# Config LEMP
############################################
# Config SSL
self_signed_ssl() {
    #Create dhparams
    self_signed_dir="/etc/nginx/ssl/server"
    mkdir -p "${self_signed_dir}"
    openssl dhparam -out /etc/nginx/ssl/dhparams.pem 2048
    openssl genrsa -out "${self_signed_dir}/server.key" 4096
    openssl req -new -key "${self_signed_dir}/server.key" \
        -out "${self_signed_dir}/server.csr" -subj "/C=VN/ST=Caugiay/L=Hanoi/O=Hostvn/OU=IT Department/CN=${IPADDRESS}"
    openssl x509 -in "${self_signed_dir}/server.csr" -out "${self_signed_dir}/server.crt" \
        -req -signkey "${self_signed_dir}/server.key" -days 3650
}

# Config Nginx
create_nginx_conf() {
    mkdir -p /etc/nginx/alias
    mkdir -p /etc/nginx/redirect
    mkdir -p /etc/nginx/php
    mkdir -p /etc/nginx/conf.d
    mkdir -p /etc/nginx/pagespeed
    mkdir -p /usr/share/nginx/html/
    chown -R nginx. /usr/share/nginx/html/
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf."$(date +%Y-%m-%d)"

    cat >>"/etc/nginx/nginx.conf" <<EONGINXCONF
user nginx;
worker_processes auto;
worker_rlimit_nofile 260000;

error_log  /var/log/nginx/error.log warn;
pid        /run/nginx.pid;

events {
    worker_connections ${MAX_CLIENT};
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
    # limit the number of connections per single IP
    limit_conn_zone \$binary_remote_addr zone=conn_limit_per_ip:10m;
    # limit the number of requests for a given session
    limit_req_zone \$binary_remote_addr zone=req_limit_per_ip:10m rate=1r/s;

    # Custom Response Headers
    more_set_headers 'Server: HOSTVN.NET';
    more_set_headers 'X-Content-Type-Options    "nosniff" always';
    more_set_headers 'X-XSS-Protection          "1; mode=block" always';
    more_set_headers 'Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always';
    more_set_headers 'Referrer-Policy no-referrer-when-downgrade';
    
    # Custom Variables
    map \$scheme \$https_suffix { default ''; https '-https'; }

    include /etc/nginx/extra/nginx_cache.conf;
    include /etc/nginx/extra/gzip.conf;
    include /etc/nginx/extra/brotli.conf;
    include /etc/nginx/extra/ssl.conf;
    include /etc/nginx/extra/cloudflare.conf;
    include /etc/nginx/web_apps.conf;
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/redirect/*.conf;
}
EONGINXCONF
}

_create_mod_security_config(){
    mkdir -p /etc/nginx/modsec
    cp /usr/share/nginx_module/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
    cp /usr/share/nginx_module/ModSecurity/unicode.mapping /etc/nginx/modsec
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    rm -rf /etc/nginx/modsec/main.conf
    cat >> "/etc/nginx/modsec/main.conf" << EOmodsec_main
include /etc/nginx/modsec/modsecurity.conf
include /etc/nginx/owasp-modsecurity-crs/crs-setup.conf
include /etc/nginx/owasp-modsecurity-crs/rules/*.conf
EOmodsec_main

    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
    cd_dir owasp-modsecurity-crs
    mv crs-setup.conf.example crs-setup.conf
    cd_dir rules
    mv RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
    cd_dir "${DIR}"
}

create_wordpress_conf() {
    mkdir -p /etc/nginx/wordpress
    cat >>"/etc/nginx/wordpress/disable_xmlrpc.conf" <<EOxmlrpc
# Disable XML-RPC
location = /xmlrpc.php { deny all; access_log off; log_not_found off; }
EOxmlrpc

    cat >>"/etc/nginx/wordpress/disable_user_api.conf" <<EOuser_api
#Block API User
location ~* /wp-json/wp/v2/users {
    allow 127.0.0.1;
    deny all;
    access_log off;
    log_not_found off;
}
EOuser_api

    cat >> "/etc/nginx/wordpress/webp_express.conf" << EOwebp_express
# WebP Express rules
location ~* ^/?wp-content/.*\.(png|jpe?g)$ {
    add_header Vary Accept;
    expires 365d;
    if (\$http_accept !~* "webp"){
        break;
    }
    try_files
        /wp-content/webp-express/webp-images/doc-root/\$uri.webp
        \$uri.webp
        /wp-content/plugins/webp-express/wod/webp-on-demand.php?xsource=x\$request_filename&wp-content=wp-content
        ;
}

# Route requests for non-existing webps to the converter
location ~* ^/?wp-content/.*\.(png|jpe?g)\.webp$ {
    try_files
        \$uri
        /wp-content/plugins/webp-express/wod/webp-realizer.php?xdestination=x\$request_filename&wp-content=wp-content
        ;
}
# (WebP Express rules ends here)
EOwebp_express

    cat >>"/etc/nginx/wordpress/wordpress_secure.conf" <<EOwpsecure
rewrite /wp-admin$ \$scheme://\$host\$uri/ permanent;

location /wp-includes/{
    location ~ \.(gz|tar|bzip2|7z|php|php5|php7|log|error|py|pl|kid|love|cgi)\$ { deny all; }
}
location /wp-content/uploads {
    location ~ \.(gz|tar|bzip2|7z|php|php5|php7|log|error|py|pl|kid|love|cgi)\$ { deny all; }
}
location /wp-content/updraft { deny all; access_log off; log_not_found off; }
location /wp-content/backups-dup-pro { deny all; access_log off; log_not_found off; }
location /wp-snapshots { deny all; access_log off; log_not_found off; }
location /wp-content/uploads/sucuri { deny all; access_log off; log_not_found off; }
location /wp-content/uploads/nginx-helper { deny all; access_log off; log_not_found off; }
location = /wp-config.php { deny all; access_log off; log_not_found off; }
location = /wp-links-opml.php { deny all; access_log off; log_not_found off; }
location = /wp-config-sample.php { deny all; access_log off; log_not_found off; }
location = /readme.html { deny all; access_log off; log_not_found off; }
location = /license.txt { deny all; access_log off; log_not_found off; }

# enable gzip on static assets - php files are forbidden
location /wp-content/cache {
# Cache css & js files
    location ~* \.(?:css(\.map)?|js(\.map)?|.html)\$ {
        add_header Access-Control-Allow-Origin *;
        access_log off;
        log_not_found off;
        expires 365d;
    }
    location ~ \.php\$ { deny all; access_log off; log_not_found off; }
}
EOwpsecure

    cat >>"/etc/nginx/wordpress/yoast_seo.conf" <<EOyoast_seo
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

    cat >>"/etc/nginx/wordpress/rank_math_seo.conf" <<EOrank_math_seo
# RANK MATH SEO plugin
rewrite ^/sitemap_index.xml\$ /index.php?sitemap=1 last;
rewrite ^/([^/]+?)-sitemap([0-9]+)?.xml\$ /index.php?sitemap=\$1&sitemap_n=\$2 last;
EOrank_math_seo

    cat >>"/etc/nginx/wordpress/w3c.conf" <<EOw3c
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
    add_header X-Frame-Options "SAMEORIGIN";
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
    add_header X-Frame-Options "SAMEORIGIN";
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
    add_header X-Frame-Options "SAMEORIGIN";
    add_header Vary "Accept-Encoding";
}
location ~ \.(css|htc|less|js|js2|js3|js4)\$ {
    expires 31536000s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header Vary "Accept-Encoding";
    try_files \$uri \$uri/ /index.php?\$args;
}
location ~ \.(html|htm|rtf|rtx|txt|xsd|xsl|xml)\$ {
    expires 3600s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header Vary "Accept-Encoding";
    try_files \$uri \$uri/ /index.php?\$args;
}
location ~ \.(asf|asx|wax|wmv|wmx|avi|bmp|class|divx|doc|docx|exe|gif|gz|gzip|ico|jpg|jpeg|jpe|webp|json|mdb|mid|midi|mov|qt|mp3|m4a|mp4|m4v|mpeg|mpg|mpe|webm|mpp|_otf|odb|odc|odf|odg|odp|ods|odt|ogg|pdf|png|pot|pps|ppt|pptx|ra|ram|svg|svgz|swf|tar|tif|tiff|_ttf|wav|wma|wri|xla|xls|xlsx|xlt|xlw|zip)\$ {
    expires 31536000s;
    etag on;
    if_modified_since exact;
    add_header Pragma "public";
    add_header Cache-Control "public";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header Vary "Accept-Encoding";
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

    cat >>"/etc/nginx/wordpress/wpfc.conf" <<EOwpfc
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
location @cachemiss { try_files \$uri \$uri/ /index.php\$is_args\$args; }

include /etc/nginx/extra/staticfiles.conf;
EOwpfc

    cat >>"/etc/nginx/wordpress/wpsc.conf" <<EOwpsc
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

    cat >>"/etc/nginx/wordpress/enabler.conf" <<EOenabler
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

location @cachemiss { try_files \$uri \$uri/ /index.php\$is_args\$args; }

include /etc/nginx/extra/staticfiles.conf;
EOenabler

    cat >>"/etc/nginx/wordpress/swift2.conf" <<EOswift2
set \$swift_cache 1;
if (\$request_method = POST){ set \$swift_cache 0; }
if (\$args != ''){ set \$swift_cache 0; }
if (\$http_cookie ~* "wordpress_logged_in") { set \$swift_cache 0; }
if (\$request_uri ~ ^/wp-content/cache/swift-performance/([^/]*)/assetproxy) { set \$swift_cache 0; }

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
create_extra_conf() {
    # Include http block
    if [[ ! -d "/etc/nginx/extra" ]]; then
        mkdir -p /etc/nginx/extra
    fi

    cat >> "/etc/nginx/extra/brotli.conf" << EOFBRCONF
##Brotli Compression
brotli on;
brotli_static on;
brotli_buffers 16 8k;
brotli_comp_level 5;
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

    cat >> "/etc/nginx/extra/nginx_cache.conf" << EOnginx_cache
fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
EOnginx_cache

    cat >> "/etc/nginx/extra/skip_cache.conf" << EOskip_cache
# Enable SSI
# https://en.wikipedia.org/wiki/Server_Side_Includes
ssi on;

# Enable caching for all by default
set \$skip_cache 0;

# Disable cache for all requests except GET and HEAD
if (\$request_method !~ ^(GET|HEAD)$) { set \$skip_cache 1; }

# Disable cache for all requests with a query string
# You should disable this section if you use query string only for users tracking
if (\$query_string != "") { set \$skip_cache 1; }

# Disable cache for all logged in users or recent commenters
# Add your custom cookies here!
if (\$http_cookie ~* "nginx_no_cache|PHPSESSID") { set \$skip_cache 1; }
# Wordpress
if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
    set \$skip_cache 1;
}
# Magento
if (\$http_cookie ~* "frontend_cid|frontend|sid|adminhtml|EXTERNAL_NO_CACHE") { set \$skip_cache 1; }

# Disable cache for uris containing the following segments
# If is evil and you can speedup this section by using locations instead
# https://www.nginx.com/resources/wiki/start/topics/depth/ifisevil/
# https://serverfault.com/questions/509327/can-we-jump-to-another-location-from-a-location-in-nginx
# Best practice
if (\$request_uri ~* "/ping|/metrics|/nginx_status|/admin|/administrator|/login|/feed|index.php|sitemap(_index)?.xml") {
    set \$skip_cache 1;
}
# Wordpress
if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
    set \$skip_cache 1;
}
# Magento
# http://devdocs.magento.com/guides/v2.0/config-guide/varnish/config-varnish.html
if (\$request_uri ~* "(index|litespeed).php|admin|api|cron.php|/checkout/|/account/|/brand-ambassador/|/brand-ambassador-coupon/|/brand-ambassador-program/|/affiliateplusstatistic/|/brand-ambassador/index/listTransaction/|/brand-ambassador/index/paymentForm/|/brand-ambassador-program/index/index/|/brand-ambassador/banner/list/|/brand-ambassador-coupon/index/index/|/brand-ambassador/refer/index/|/brand-ambassador/index/payments/|/brand-ambassador/index/referrers/|/affiliateplusstatistic/statistic/index/|/brand-ambassador/account/edit/|/checkout/cart/|/repeat-delivery") {
    set \$skip_cache 1;
}
EOskip_cache

    cat >> "/etc/nginx/extra/skip_cache_woo.conf" << EOskip_cache_woo
#WooCommerce
if (\$request_uri ~* "/store.*|/cart.*|/my-account.*|/checkout.*|/addons.*") {
         set \$skip_cache 1;
}
if ( \$arg_add-to-cart != "" ) {
      set \$skip_cache 1;
}
if ( \$cookie_woocommerce_items_in_cart != "0" ) {
    set \$skip_cache 1;
}
EOskip_cache_woo

    cat >> "/etc/nginx/extra/https.conf" << EOredirect_https
if (\$http_x_forwarded_proto != 'https') { return 301 https://\$host\$request_uri; }
EOredirect_https

    cat >>"/etc/nginx/extra/gzip.conf" <<EOFGZCONF
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

    cat >>"/etc/nginx/extra/ssl.conf" <<EOFSSLCONF
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

    cat > "/etc/nginx/extra/cloudflare.conf" << END
real_ip_header X-Forwarded-For;
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
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2a06:98c0::/29;
set_real_ip_from 2c0f:f248::/32;
END

    # cron_cf_exists=$(crontab -l | grep -w 'updateCloudflareRangeIP')
    # if [ -z "${cron_cf_exists}" ]; then
    #     crontab -l > updateCf
    #     echo "0 3 * * * bash /var/hostvn/menu/cronjob/updateCloudflareRangeIP >/dev/null 2>&1" >> updateCf
    #     crontab updateCf
    #     rm -rf updateCf
    # fi

#    cat >>"/etc/nginx/extra/cloudflare.conf" <<EOCF
#real_ip_header X-Forwarded-For;
#set_real_ip_from 173.245.48.0/20
#set_real_ip_from 103.21.244.0/22
#set_real_ip_from 103.22.200.0/22
#set_real_ip_from 103.31.4.0/22
#set_real_ip_from 141.101.64.0/18
#set_real_ip_from 108.162.192.0/18
#set_real_ip_from 190.93.240.0/20
#set_real_ip_from 188.114.96.0/20
#set_real_ip_from 197.234.240.0/22
#set_real_ip_from 198.41.128.0/17
#set_real_ip_from 162.158.0.0/15
#set_real_ip_from 104.16.0.0/12
#set_real_ip_from 172.64.0.0/13
#set_real_ip_from 131.0.72.0/22
#set_real_ip_from 2400:cb00::/32
#set_real_ip_from 2606:4700::/32
#set_real_ip_from 2803:f800::/32
#set_real_ip_from 2405:b500::/32
#set_real_ip_from 2405:8100::/32
#set_real_ip_from 2a06:98c0::/29
#EOCF

    cat >>"/etc/nginx/extra/nginx_limits.conf" <<EOCF
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
    cat >>"/etc/nginx/extra/staticfiles.conf" <<EOSTATICFILES
location = /favicon.ico { allow all; log_not_found off; access_log off; }
location = /robots.txt { allow all; log_not_found off; access_log off; }
location ~* \.(gif|jpg|jpeg|png|ico|webp)\$ {
    gzip_static off;
    brotli_static off;
    #add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 365d;
    break;
}
location ~* \.(3gp|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso)\$ {
    gzip_static off;
    brotli_static off;
    sendfile off;
    sendfile_max_chunk 1m;
    #add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 365d;
    break;
}
location ~* \.(js)\$ {
    #add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 365d;
    break;
}
location ~* \.(css)\$ {
    #add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate, immutable, stale-while-revalidate=86400, stale-if-error=604800";
    access_log off;
    expires 365d;
    break;
}
location ~* \.(eot|svg|ttf|woff|woff2)\$ {
    #add_header Access-Control-Allow-Origin *;
    add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    access_log off;
    expires 365d;
    break;
}
EOSTATICFILES

    cat >>"/etc/nginx/extra/security.conf" <<EOsecurity
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
    access_log off;
    log_not_found off;
}
EOsecurity
}

vhost_custom() {
    REWRITE_CONFIG_PATH="/etc/nginx/rewrite"
    mkdir -p "${REWRITE_CONFIG_PATH}"
    cat >>"${REWRITE_CONFIG_PATH}/default.conf" <<EOrewrite_default
location / { try_files \$uri \$uri/ /index.php?\$query_string; }
EOrewrite_default

    cat >>"${REWRITE_CONFIG_PATH}/codeigniter.conf" <<EOrewrite_ci
location / { try_files \$uri \$uri/ /index.php?/\$request_uri; }
EOrewrite_ci

    cat >>"${REWRITE_CONFIG_PATH}/discuz.conf" <<EOrewrite_discuz
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

    cat >>"${REWRITE_CONFIG_PATH}/drupal.conf" <<EOrewrite_drupal
location / { try_files \$uri /index.php?\$query_string; }
location ~ \..*/.*\.php\$ { return 403; }
location ~ ^/sites/.*/private/ { return 403; }
# Block access to scripts in site files directory
location ~ ^/sites/[^/]+/files/.*\.php\$ { deny all; }
location ~ (^|/)\. { return 403; }
location ~ /vendor/.*\.php\$ { deny all; return 404; }
location @rewrite { rewrite ^/(.*)\$ /index.php?q=\$1; }
location ~* \.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?\$|composer\.(lock|json)\$|web\.config\$|^(\.(?!well-known).*|Entries.*|Repository|Root|Tag|Template)\$|^#.*#\$|\.php(~|\.sw[op]|\.bak|\.orig|\.save)\$ {
    deny all;
    return 404;
}
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)\$ {
    try_files \$uri @rewrite;
    expires max;
    log_not_found off;
}
location ~ ^/sites/.*/files/styles/ { try_files \$uri @rewrite; }
location ~ ^(/[a-z\-]+)?/system/files/ { try_files \$uri /index.php?\$query_string; }
if (\$request_uri ~* "^(.*/)index\.php/(.*)") { return 307 \$1\$2; }
EOrewrite_drupal

    cat >>"${REWRITE_CONFIG_PATH}/ecshop.conf" <<EOrewrite_ecshop
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

    cat >>"${REWRITE_CONFIG_PATH}/xenforo.conf" <<EOrewrite_xenforo
location / { try_files \$uri \$uri/ /index.php?\$uri&\$args; }
location /install/data/ { internal; }
location /install/templates/ { internal; }
location /internal_data/ { internal; }
location /library/ { internal; }
location /src/ { internal; }
EOrewrite_xenforo

    cat >>"${REWRITE_CONFIG_PATH}/joomla.conf" <<EOjoomla
location / { try_files \$uri \$uri/ /index.php?\$args; }
EOjoomla

    cat >>"${REWRITE_CONFIG_PATH}/whmcs.conf" <<EOwhmcs
location ~ /announcements/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/announcements/\$1; }

location ~ /download/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/download\$1; }

location ~ /knowledgebase/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/knowledgebase/\$1; }

location ~ /store/ssl-certificates/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/store/ssl-certificates/\$1; }

location ~ /store/sitelock/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/store/sitelock/\$1; }

location ~ /store/website-builder/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/store/website-builder/\$1; }

location ~ /store/order/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/store/order/\$1; }

location ~ /cart/domain/renew/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/cart/domain/renew\$1; }

location ~ /account/paymentmethods/?(.*)\$ { rewrite ^/(.*)\$ /index.php?rp=/account/paymentmethods\$1; }

location ~ /admin/(addons|apps|domains|help\/license|services|setup|utilities\/system\/php-compat)(.*) {
    rewrite ^/(.*)\$ /admin/index.php?rp=/admin/\$1\$2 last;
}
EOwhmcs

    cat >>"${REWRITE_CONFIG_PATH}/wordpress.conf" <<EOwordpress
location / { try_files \$uri \$uri/ /index.php?\$args; }
EOwordpress

    cat >>"${REWRITE_CONFIG_PATH}/prestashop.conf" <<EOprestashop
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

    cat >>"${REWRITE_CONFIG_PATH}/opencart.conf" <<EOopencart
rewrite /admin\$ \$scheme://\$host\$uri/ permanent;
rewrite ^/download/(.*) /index.php?route=error/not_found last;
rewrite ^/image-smp/(.*) /index.php?route=product/smp_image&name=\$1 break;
location = /sitemap.xml {
    rewrite ^(.*)\$ /index.php?route=feed/google_sitemap break;
}
location = /googlebase.xml { rewrite ^(.*)\$ /index.php?route=feed/google_base break; }
location / { try_files \$uri \$uri/ @opencart; }
location @opencart { rewrite ^/(.+)\$ /index.php?_route_=\$1 last; }
location /admin { index index.php; }
EOopencart

    cat >>"${REWRITE_CONFIG_PATH}/laravel.conf" <<EOlaravel
location / { try_files \$uri \$uri/ /index.php?\$query_string; }
EOlaravel

    cat >>"${REWRITE_CONFIG_PATH}/cakephp.conf" <<EOcake_php
location / { try_files \$uri \$uri/ /index.php\$is_args\$args; }
EOcake_php

    cat >>"${REWRITE_CONFIG_PATH}/yii.conf" <<EOyii
location / { try_files \$uri \$uri/ /index.php\$is_args\$args; }
location ~ \.(js|css|png|jpg|gif|swf|ico|pdf|mov|fla|zip|rar)$ { try_files \$uri =404; }
location ~ /(protected|framework|themes/\w+/views) { deny all; }
EOyii
}

# Config default server block
default_vhost() {
    NGINX_VHOST_PATH="/etc/nginx/conf.d"
    mkdir -p "${USR_DIR}"/nginx/auth
    mkdir -p /etc/nginx/apps

    if [[ -f "${NGINX_VHOST_PATH}/default.conf" ]]; then
        rm -rf "${NGINX_VHOST_PATH}"/default.conf
    fi

    cat >>"/etc/nginx/apps/phpmyadmin.conf" <<EOphpmyadmin_vhost
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

    cat >>"/etc/nginx/apps/opcache.conf" <<EOopcache_vhost
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
        if (-f \$request_filename) { fastcgi_pass php-app; }
    }
    location ~* ^/opcache/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ { root ${DEFAULT_DIR_TOOL}/; }
}
EOopcache_vhost

    cat >>"/etc/nginx/apps/memcached.conf" <<EOmemcached_vhost
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
        if (-f \$request_filename) { fastcgi_pass php-app; }
    }
    location ~* ^/memcached/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
EOmemcached_vhost

    cat >>"/etc/nginx/apps/redis.conf" <<EOredis_vhost
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
        if (-f \$request_filename) { fastcgi_pass php-app; }
    }
    location ~* ^/redis/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|webp|xml|txt))\$ {
        root ${DEFAULT_DIR_TOOL}/;
    }
}
EOredis_vhost

    cat >>"/etc/nginx/web_apps.conf" <<EOdefault_vhost
upstream php-app {
    server unix:/var/run/php-fpm.sock;
}

server {
    listen 80 default_server;
    root /usr/share/nginx/html/;
    index index.html index.htm;
    include /etc/nginx/extra/security.conf;
    error_page 400 401 403 404 500 502 503 504 /50x.html;
}

server {
    listen 443 ssl http2 default_server;
    root /usr/share/nginx/html/;
    index index.html index.htm;

    ssl_certificate         /etc/nginx/ssl/server/server.crt;
    ssl_certificate_key     /etc/nginx/ssl/server/server.key;

    include /etc/nginx/extra/security.conf;
    error_page 400 401 403 404 500 502 503 504 /50x.html;
}

server {
    listen ${RANDOM_ADMIN_PORT};

    server_name ${IPADDRESS};

    access_log off;
    log_not_found off;
    error_log /var/log/nginx/error.log;

    root ${DEFAULT_DIR_TOOL};
    index index.php index.html index.htm;

    auth_basic "Restricted";
    auth_basic_user_file ${USR_DIR}/nginx/auth/.htpasswd;

    include /etc/nginx/apps/phpmyadmin.conf;
    include /etc/nginx/apps/opcache.conf;
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

default_index() {
    if [[ -f "${DEFAULT_DIR_WEB}/index.html" ]]; then
        rm -rf "${DEFAULT_DIR_WEB}"/index.html
    fi

    cat >>"${DEFAULT_DIR_WEB}/index.html" <<EOdefault_index
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

    cp "${DEFAULT_DIR_WEB}"/index.html ${DEFAULT_DIR_TOOL}
}

default_error_page() {
    if [[ -f "${DEFAULT_DIR_WEB}/50x.html" ]]; then
        rm -rf "${DEFAULT_DIR_WEB}"/50x.html
    fi
    cat >>"${DEFAULT_DIR_WEB}/50x.html" <<EOdefault_index
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

    cp "${DEFAULT_DIR_WEB}"/50x.html ${DEFAULT_DIR_TOOL}
}

wp_rocket_nginx() {
    cd_dir /etc/nginx
    git clone https://github.com/satellitewp/rocket-nginx.git
    cd_dir /etc/nginx/rocket-nginx
    cp rocket-nginx.ini.disabled rocket-nginx.ini
    php rocket-parser.php
}

# Config PHP-FPM
php_global_config() {
    if [[ -f "$PHP1_CONFIG_PATH/php-fpm.conf" ]]; then
        mv "$PHP1_CONFIG_PATH"/php-fpm.conf "$PHP1_CONFIG_PATH"/php-fpm.conf."$(date +%Y-%m-%d)"
    fi

    cat >>"$PHP1_CONFIG_PATH/php-fpm.conf" <<EOphp_fpm_conf
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

include=$PHP1_POOL_PATH/*.conf

[global]
pid = /run/php/php${PHP_VERSION}-fpm.pid
error_log = /var/log/php-fpm/error.log
log_level = warning
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes
EOphp_fpm_conf

    if [[ -f "$PHP1_POOL_PATH/www.conf" ]]; then
        mv "$PHP1_POOL_PATH"/www.conf "$PHP1_POOL_PATH"/www.conf."$(date +%Y-%m-%d)"
    fi
    cat >>"$PHP1_POOL_PATH/www.conf" <<EOwww_conf
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
php_admin_value[disable_functions] = exec,system,passthru,shell_exec,proc_close,proc_open,dl,popen,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname
php_admin_value[open_basedir] = /usr/share/nginx/:/tmp/:/var/tmp/:/dev/urandom:/usr/share/php/:/dev/shm:/var/lib/php/sessions/:/usr/share/doc:/var/www/:/usr/local/apache2/htdocs/
security.limit_extensions = .php
EOwww_conf

    mkdir -p /var/lib/php/session
    mkdir -p /var/lib/php/wsdlcache
    mkdir -p /var/log/php-fpm
    chown -R nginx:nginx /var/lib/php/session
    chown -R nginx:nginx /var/lib/php/wsdlcache
    chown -R nginx:nginx /var/log/php-fpm
    chmod 755 /var/lib/php/session
    chmod 755 /var/lib/php/wsdlcache
}

php2_global_config() {
    if [[ -f "$PHP2_CONFIG_PATH/php-fpm.conf" ]]; then
        mv "$PHP2_CONFIG_PATH"/php-fpm.conf "$PHP2_CONFIG_PATH"/php-fpm.conf."$(date +%Y-%m-%d)"
    fi

    cat >>"$PHP2_CONFIG_PATH/php-fpm.conf" <<EOphp_fpm_conf
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

include=$PHP2_POOL_PATH/*.conf

[global]
pid = /run/php/php${PHP_VERSION_2}-fpm.pid
error_log = /var/log/php2-fpm/error.log
log_level = warning
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes
EOphp_fpm_conf

    if [[ -f "$PHP2_POOL_PATH/www.conf" ]]; then
        mv "$PHP2_POOL_PATH"/www.conf "$PHP2_POOL_PATH"/www.conf."$(date +%Y-%m-%d)"
    fi
    cat >>"$PHP2_POOL_PATH/www.conf" <<EOwww_conf
[www]
listen = /var/run/php2-fpm.sock;
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
;slowlog = /var/log/php2-fpm/www-slow.log
chdir = /
php_admin_value[error_log] = /var/log/php2-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
php_admin_value[disable_functions] = exec,system,passthru,shell_exec,dl,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname
;php_admin_value[disable_functions] = exec,system,passthru,shell_exec,proc_close,proc_open,dl,popen,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname
;php_admin_value[open_basedir] = ${DEFAULT_DIR_TOOL}/:/tmp/:/var/tmp/:/dev/urandom:/usr/share/php/:/dev/shm:/var/lib/php/sessions/
security.limit_extensions = .php
EOwww_conf

    mkdir -p /var/lib/php/session
    mkdir -p /var/lib/php/wsdlcache
    mkdir -p /var/log/php2-fpm
    chown -R nginx:nginx /var/lib/php/session
    chown -R nginx:nginx /var/lib/php/wsdlcache
    chown -R nginx:nginx /var/log/php2-fpm
    chmod 755 /var/lib/php/session
    chmod 755 /var/lib/php/wsdlcache
}

# Custom PHP Ini
hostvn_custom_ini() {
    cat >"$PHP1_INI_PATH/00-hostvn-custom.ini" <<EOhostvn_custom_ini
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 600
max_input_time = 600
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
error_reporting = E_ALL & ~E_NOTICE
EOhostvn_custom_ini

    if [ -f "$PHP1_CLI_PATH/00-hostvn-custom.ini" ]; then
        rm -rf "$PHP1_CLI_PATH"/00-hostvn-custom.ini
    fi

    cp "$PHP1_INI_PATH"/00-hostvn-custom.ini "$PHP1_CLI_PATH"/00-hostvn-custom.ini
}

hostvn_custom_ini_2() {
    cat >"$PHP2_INI_PATH/00-hostvn-custom.ini" <<EOhostvn_custom_ini_2
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 600
max_input_time = 600
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
error_reporting = E_ALL & ~E_NOTICE
EOhostvn_custom_ini_2

    if [ -f "$PHP2_CLI_PATH/00-hostvn-custom.ini" ]; then
        rm -rf "$PHP2_CLI_PATH"/00-hostvn-custom.ini
    fi

    cp "$PHP2_INI_PATH"/00-hostvn-custom.ini "$PHP2_CLI_PATH"/00-hostvn-custom.ini
}

# Config PHP Opcache
php_opcache() {
    if [[ -f "$PHP1_INI_PATH/10-opcache.ini" ]]; then
        mv "$PHP1_INI_PATH"/10-opcache.ini "$PHP1_INI_PATH"/10-opcache.ini."$(date +%Y-%m-%d)"
    fi
    cat >"$PHP1_INI_PATH/10-opcache.ini" <<EOphp_opcache
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
opcache.blacklist_filename=${PHP1_INI_PATH}/opcache-default.blacklist
EOphp_opcache

    cat >"${PHP1_INI_PATH}/opcache-default.blacklist" <<EOopcache_blacklist
/home/*/*/public_html/wp-content/plugins/backwpup/*
/home/*/*/public_html/wp-content/plugins/duplicator/*
/home/*/*/public_html/wp-content/plugins/updraftplus/*
/home/*/*/public_html/wp-content/cache/*
/home/*/*/public_html/storage/*
EOopcache_blacklist

    rm -rf "$PHP1_CLI_PATH"/10-opcache.ini
    cp "$PHP1_INI_PATH"/10-opcache.ini "$PHP1_CLI_PATH"/10-opcache.ini
}

php_2_opcache() {
    if [[ -f "$PHP2_INI_PATH/10-opcache.ini" ]]; then
        mv "$PHP2_INI_PATH"/10-opcache.ini "$PHP2_INI_PATH"/10-opcache.ini."$(date +%Y-%m-%d)"
    fi
    cat >"$PHP2_INI_PATH/10-opcache.ini" <<EOphp_opcache
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

    cat >"${PHP2_INI_PATH}/opcache-default.blacklist" <<EOopcache_blacklist
/home/*/*/public_html/wp-content/plugins/backwpup/*
/home/*/*/public_html/wp-content/plugins/duplicator/*
/home/*/*/public_html/wp-content/plugins/updraftplus/*
/home/*/*/public_html/wp-content/cache/*
/home/*/*/public_html/storage/*
EOopcache_blacklist

    rm -rf "$PHP2_CLI_PATH"/10-opcache.ini
    cp "$PHP2_INI_PATH"/10-opcache.ini "$PHP2_CLI_PATH"/10-opcache.ini
}

# Config MariaDB
config_my_cnf() {
    mkdir -p /var/log/mysql
    chown -R mysql:mysql /var/log/mysql
    mv /etc/mysql/my.cnf /etc/mysql/my.cnf."$(date +%Y-%m-%d)"

    cat >>"/etc/mysql/my.cnf" <<EOmy_cnf
[client]
port = 3306
socket = /run/mysqld/mysqld.sock
default-character-set = utf8mb4

[mysql]
max_allowed_packet = ${max_allowed_packet}

[mysqld]
port = 3306

local-infile=0
#ignore-db-dir=lost+found
init-connect = 'SET NAMES utf8mb4'
character-set-server = utf8mb4
#collation-server      = utf8mb4_unicode_ci
datadir=/var/lib/mysql
socket = /run/mysqld/mysqld.sock

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
ft_min_word_len = 3
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
#open_files_limit=100000

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
log-error=/var/log/mysqld/mysqld.log
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

    sql_root_pass=$(gen_pass)
    sql_admin_pass=$(gen_pass)

    systemctl start mariadb
    systemctl enable mariadb

    mysql_secure_installation <<EOF

n
y
${sql_root_pass}
${sql_root_pass}
y
y
y
y
EOF

    Q1="CREATE USER 'admin'@'localhost' IDENTIFIED BY '${sql_admin_pass}';"
    Q2="GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    mysql -uroot -p"${sql_root_pass}" -e "${SQL}"

    if [ -f "/usr/lib/systemd/system/mariadb.service" ]; then
        sed -i "s/LimitNOFILE=.*/LimitNOFILE=655350/g" /usr/lib/systemd/system/mariadb.service
        sed -i "s/PrivateTmp=false/PrivateTmp=true/g" /usr/lib/systemd/system/mariadb.service
        systemctl daemon-reload
    fi

    if [[ -f "/lib/systemd/system/mariadb.service" && ! -f "/usr/lib/systemd/system/mariadb.service" ]]; then
        sed -i "s/LimitNOFILE=.*/LimitNOFILE=655350/g" /lib/systemd/system/mariadb.service
        sed -i "s/PrivateTmp=false/PrivateTmp=true/g" /lib/systemd/system/mariadb.service
        systemctl daemon-reload
    fi
}

############################################
# Change SSH Port
############################################
change_ssh_port() {
    sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
}

############################################
# Install ACME
############################################
install_acme() {
    # curl https://get.acme.sh | sh -s email="${ADMIN_EMAIL}"
    curl https://get.acme.sh | sh
}

############################################
# Generate htpasswd
############################################
gen_htpasswd() {
    ADMIN_TOOL_PWD=$(gen_pass)
    if [ ! -d "${USR_DIR}/nginx/auth" ]; then
        mkdir -p "${USR_DIR}"/nginx/auth
    fi
    if [ ! -f "/usr/bin/htpasswd" ]; then
        apt install apache2-utils -y
    fi
    htpasswd -b -c ${USR_DIR}/nginx/auth/.htpasswd admin "${ADMIN_TOOL_PWD}"
    chown -R nginx:nginx "${USR_DIR}"/nginx/auth
    chown -R nginx:nginx ${USR_DIR}/nginx/auth/.htpasswd
}

############################################
# Opcache Dashboard
############################################
opcache_dashboard() {
    mkdir -p "${DEFAULT_DIR_TOOL}"/opcache
    wget -q "${GITHUB_RAW_LINK}"/amnuts/opcache-gui/master/index.php -O "${DEFAULT_DIR_TOOL}"/opcache/index.php
    chown -R nginx:nginx "${DEFAULT_DIR_TOOL}"/opcache
    chown -R nginx:nginx "${USR_DIR}"/nginx/auth
}

############################################
# Rclone
############################################
install_rclone() {
    curl https://rclone.org/install.sh | sudo bash
}

install_wp_cli_packages() {
    sed -i '/memory_limit/d' "$PHP1_INI_PATH"/00-hostvn-custom.ini
    sed -i '/memory_limit/d' "$PHP1_CLI_PATH"/00-hostvn-custom.ini
    echo "memory_limit = -1" >>"$PHP1_INI_PATH"/00-hostvn-custom.ini
    echo "memory_limit = -1" >>"$PHP1_CLI_PATH"/00-hostvn-custom.ini

    systemctl restart php"${PHP_VERSION}"-fpm

    wp package install iandunn/wp-cli-rename-db-prefix --allow-root
    wp package install trepmal/wp-revisions-cli --allow-root

    sed -i '/memory_limit/d' "$PHP1_INI_PATH"/00-hostvn-custom.ini
    sed -i '/memory_limit/d' "$PHP1_CLI_PATH"/00-hostvn-custom.ini
    echo "memory_limit = ${MAX_MEMORY}M" >>"$PHP1_INI_PATH"/00-hostvn-custom.ini
    echo "memory_limit = ${MAX_MEMORY}M" >>"$PHP1_CLI_PATH"/00-hostvn-custom.ini

#    echo "allow_url_fopen = Off" >> "$PHP2_INI_PATH"/00-hostvn-custom.ini
#    echo "allow_url_fopen = Off" >> "$PHP2_CLI_PATH"/00-hostvn-custom.ini
#    echo "allow_url_fopen = Off" >> "$PHP1_INI_PATH"/00-hostvn-custom.ini
#    echo "allow_url_fopen = Off" >> "$PHP1_CLI_PATH"/00-hostvn-custom.ini

    systemctl restart php"${PHP_VERSION}"-fpm
}

############################################
# Fail2ban
############################################
install_fail2ban() {
    apt-get install fail2ban -y
    cp /etc/fail2ban/jail.{conf,local}
    if [ -f "/etc/fail2ban/jail.d/defaults-debian.conf" ]; then
        rm -rf /etc/fail2ban/jail.d/defaults-debian.conf
    fi

    ssh_port="ssh"
    if [[ "$prompt_ssh" =~ ^([yY]) ]]; then
        ssh_port=8282
    fi

    mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local."$(date +%Y-%m-%d)"

    cat > "/etc/fail2ban/jail.local" << EOjail_local
[INCLUDES]
before = paths-debian.conf

[DEFAULT]
ignorecommand =
bantime  = 48h
findtime  = 10m
maxretry = 5
backend = auto
usedns = warn
logencoding = auto
enabled = false
filter = %(__name__)s[mode=%(mode)s]
destemail  = ${ADMIN_EMAIL}
sender     = ${ADMIN_EMAIL}
mta = sendmail
protocol = tcp
chain = <known/chain>
port = 0:65535
fail2ban_agent = Fail2Ban/%(fail2ban_version)s
banaction = iptables-multiport
banaction_allports = iptables-allports
action_ = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mw = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
            %(mta)s-whois[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mwl = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
action_xarf = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             xarf-login-attack[service=%(__name__)s, sender="%(sender)s", logpath=%(logpath)s, port="%(port)s"]
action_cf_mwl = cloudflare[cfuser="%(cfemail)s", cftoken="%(cfapikey)s"]
                %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
action_blocklist_de  = blocklist_de[email="%(sender)s", service=%(filter)s, apikey="%(blocklist_de_apikey)s", agent="%(fail2ban_agent)s"]
action_badips = badips.py[category="%(__name__)s", banaction="%(banaction)s", agent="%(fail2ban_agent)s"]
action_badips_report = badips[category="%(__name__)s", agent="%(fail2ban_agent)s"]
action_abuseipdb = abuseipdb
action = %(action_)s

[sshd]
port    = ${ssh_port}
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[dropbear]
port     = ssh
logpath  = %(dropbear_log)s
backend  = %(dropbear_backend)s

[selinux-ssh]
port     = ssh
logpath  = %(auditd_log)s

[apache-auth]
port     = http,https
logpath  = %(apache_error_log)s

[apache-badbots]
port     = http,https
logpath  = %(apache_access_log)s
bantime  = 48h
maxretry = 1

[apache-noscript]
port     = http,https
logpath  = %(apache_error_log)s

[apache-overflows]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-nohome]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-botsearch]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-fakegooglebot]
port     = http,https
logpath  = %(apache_access_log)s
maxretry = 1
ignorecommand = %(ignorecommands_dir)s/apache-fakegooglebot <ip>

[apache-modsecurity]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-shellshock]
port    = http,https
logpath = %(apache_error_log)s
maxretry = 1

[openhab-auth]
filter = openhab
action = iptables-allports[name=NoAuthFailures]
logpath = /opt/openhab/logs/request.log

[nginx-http-auth]
port    = ${RANDOM_ADMIN_PORT}
logpath = %(nginx_error_log)s

[nginx-limit-req]
port    = http,https
logpath = %(nginx_error_log)s

[nginx-botsearch]
port     = http,https
logpath  = %(nginx_error_log)s
maxretry = 2

[php-url-fopen]
port    = http,https
logpath = %(nginx_access_log)s
          %(apache_access_log)s

[suhosin]
port    = http,https
logpath = %(suhosin_log)s

[lighttpd-auth]
port    = http,https
logpath = %(lighttpd_error_log)s

[roundcube-auth]
port     = http,https
logpath  = %(roundcube_errors_log)s

[openwebmail]
port     = http,https
logpath  = /var/log/openwebmail.log

[horde]
port     = http,https
logpath  = /var/log/horde/horde.log

[groupoffice]
port     = http,https
logpath  = /home/groupoffice/log/info.log

[sogo-auth]
port     = http,https
logpath  = /var/log/sogo/sogo.log

[tine20]
logpath  = /var/log/tine20/tine20.log
port     = http,https

[drupal-auth]
port     = http,https
logpath  = %(syslog_daemon)s
backend  = %(syslog_backend)s

[guacamole]
port     = http,https
logpath  = /var/log/tomcat*/catalina.out

[monit]
#Ban clients brute-forcing the monit gui login
port = 2812
logpath  = /var/log/monit

[webmin-auth]
port    = 10000
logpath = %(syslog_authpriv)s
backend = %(syslog_backend)s

[froxlor-auth]
port    = http,https
logpath  = %(syslog_authpriv)s
backend  = %(syslog_backend)s

[squid]
port     =  80,443,3128,8080
logpath = /var/log/squid/access.log

[3proxy]
port    = 3128
logpath = /var/log/3proxy.log

[proftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(proftpd_log)s
backend  = %(proftpd_backend)s

[pure-ftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(pureftpd_log)s
backend  = %(pureftpd_backend)s

[gssftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(syslog_daemon)s
backend  = %(syslog_backend)s

[wuftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(wuftpd_log)s
backend  = %(wuftpd_backend)s

[vsftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(vsftpd_log)s

[assp]
port     = smtp,465,submission
logpath  = /root/path/to/assp/logs/maillog.txt

[courier-smtp]
port     = smtp,465,submission
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s

[postfix]
mode    = more
port    = smtp,465,submission
logpath = %(postfix_log)s
backend = %(postfix_backend)s

[postfix-rbl]
filter   = postfix[mode=rbl]
port     = smtp,465,submission
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s
maxretry = 1

[sendmail-auth]
port    = submission,465,smtp
logpath = %(syslog_mail)s
backend = %(syslog_backend)s

[sendmail-reject]
port     = smtp,465,submission
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s

[qmail-rbl]
filter  = qmail
port    = smtp,465,submission
logpath = /service/qmail/log/main/current

[dovecot]
port    = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s

[sieve]
port   = smtp,465,submission
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s

[solid-pop3d]
port    = pop3,pop3s
logpath = %(solidpop3d_log)s

[exim]
port   = smtp,465,submission
logpath = %(exim_main_log)s

[exim-spam]
port   = smtp,465,submission
logpath = %(exim_main_log)s

[kerio]
port    = imap,smtp,imaps,465
logpath = /opt/kerio/mailserver/store/logs/security.log

[courier-auth]
port     = smtp,465,submission,imap,imaps,pop3,pop3s
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s

[postfix-sasl]
filter   = postfix[mode=auth]
port     = smtp,465,submission,imap,imaps,pop3,pop3s
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s

[perdition]
port   = imap,imaps,pop3,pop3s
logpath = %(syslog_mail)s
backend = %(syslog_backend)s

[squirrelmail]
port = smtp,465,submission,imap,imap2,imaps,pop3,pop3s,http,https,socks
logpath = /var/lib/squirrelmail/prefs/squirrelmail_access_log

[cyrus-imap]
port   = imap,imaps
logpath = %(syslog_mail)s
backend = %(syslog_backend)s

[uwimap-auth]
port   = imap,imaps
logpath = %(syslog_mail)s
backend = %(syslog_backend)s

[named-refused]
port     = domain,953
logpath  = /var/log/named/security.log

[nsd]
port     = 53
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
logpath = /var/log/nsd.log

[asterisk]
port     = 5060,5061
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
           %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s"]
logpath  = /var/log/asterisk/messages
maxretry = 10

[freeswitch]
port     = 5060,5061
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
           %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s"]
logpath  = /var/log/freeswitch.log
maxretry = 10

[mysqld-auth]
port     = 3306
logpath  = %(mysql_log)s
backend  = %(mysql_backend)s

[mongodb-auth]
port     = 27017
logpath  = /var/log/mongodb/mongodb.log

[recidive]
logpath  = /var/log/fail2ban.log
banaction = %(banaction_allports)s
bantime  = 1w
findtime = 1d

[pam-generic]
banaction = %(banaction_allports)s
logpath  = %(syslog_authpriv)s
backend  = %(syslog_backend)s

[xinetd-fail]
banaction = iptables-multiport-log
logpath   = %(syslog_daemon)s
backend   = %(syslog_backend)s
maxretry  = 2

[stunnel]
logpath = /var/log/stunnel4/stunnel.log

[ejabberd-auth]
port    = 5222
logpath = /var/log/ejabberd/ejabberd.log

[counter-strike]
logpath = /opt/cstrike/logs/L[0-9]*.log
# Firewall: http://www.cstrike-planet.com/faq/6
tcpport = 27030,27031,27032,27033,27034,27035,27036,27037,27038,27039
udpport = 1200,27000,27001,27002,27003,27004,27005,27006,27007,27008,27009,27010,27011,27012,27013,27014,27015
action  = %(banaction)s[name=%(__name__)s-tcp, port="%(tcpport)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(udpport)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]

[nagios]
logpath  = %(syslog_daemon)s     ; nrpe.cfg may define a different log_facility
backend  = %(syslog_backend)s
maxretry = 1

[oracleims]
logpath = /opt/sun/comms/messaging64/log/mail.log_current
banaction = %(banaction_allports)s

[directadmin]
logpath = /var/log/directadmin/login.log
port = 2222

[portsentry]
logpath  = /var/lib/portsentry/portsentry.history
maxretry = 1

[pass2allow-ftp]
port         = ftp,ftp-data,ftps,ftps-data
knocking_url = /knocking/
filter       = apache-pass[knocking_url="%(knocking_url)s"]
logpath      = %(apache_access_log)s
blocktype    = RETURN
returntype   = DROP
action       = %(action_)s[blocktype=%(blocktype)s, returntype=%(returntype)s]
bantime      = 1h
maxretry     = 1
findtime     = 1

[murmur]
# AKA mumble-server
port     = 64738
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol=tcp, chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol=udp, chain="%(chain)s", actname=%(banaction)s-udp]
logpath  = /var/log/mumble-server/mumble-server.log

[screensharingd]
# For Mac OS Screen Sharing Service (VNC)
logpath  = /var/log/system.log
logencoding = utf-8

[haproxy-http-auth]
logpath  = /var/log/haproxy.log

[slapd]
port    = ldap,ldaps
logpath = /var/log/slapd.log

[domino-smtp]
port    = smtp,ssmtp
logpath = /home/domino01/data/IBM_TECHNICAL_SUPPORT/console.log

[phpmyadmin-syslog]
port    = http,https
logpath = %(syslog_authpriv)s
backend = %(syslog_backend)s

[zoneminder]
port    = http,https
logpath = %(apache_error_log)s
EOjail_local

    cat >>"/etc/fail2ban/jail.d/defaults.conf" <<END
[DEFAULT]
ignoreip   = 127.0.0.1
findtime   = 120s
destemail  = ${ADMIN_EMAIL}
sender     = ${ADMIN_EMAIL}
sendername = Fail2ban
mta        = sendmail
action     = %(action_mwl)s
END
    cat >>"/etc/fail2ban/jail.d/nginx-http-auth.conf" <<END
[nginx-http-auth]
enabled  = true
filter   = nginx-http-auth
port     = ${RANDOM_ADMIN_PORT}
logpath  = /var/log/nginx/error.log;
maxretry = 5
bantime  = 86400
END
    cat >>"/etc/fail2ban/jail.d/sshd.local" <<END
[sshd]
enabled  = true
filter   = sshd
port     = ${ssh_port}
logpath  = %(sshd_log)s
maxretry = 5
bantime  = 86400
END

    systemctl start fail2ban
    systemctl enable fail2ban
}

############################################
# SFTP
############################################

setup_sftp(){
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config."$(date +%Y-%m-%d)"

    check_sshd_config=$(grep -w "filetransfer" "/etc/ssh/sshd_config")
    if [ -z "${check_sshd_config}" ]; then
        cat >> "/etc/ssh/sshd_config" << END
Match Group filetransfer
    ChrootDirectory %h                    # Prevent user access to anything beyond their home folder
    X11Forwarding no                      # Disable X11 forwarding
    AllowTcpForwarding no                 # Disable tunneling
    AllowAgentForwarding no               # Disable port forwarding
    PermitTunnel no                       # Disable network tunneling
    ForceCommand internal-sftp            # Force the connection to use the built-in SFTP server
    PasswordAuthentication yes
END
    fi

    check_group=$(grep filetransfer /etc/group)
    if [ -z "${check_group}" ]; then
        addgroup filetransfer
    fi
}

# Create menu
############################################
add_menu() {
    cd_dir "${BASH_DIR}"
    rm -rf menu hostvn.conf ipaddress menu.tar.gz /usr/bin/hostvn
    wget "${EXT_LINK}"/ubuntu/menu.tar.gz  > /dev/null
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
}

############################################
# Write Info
############################################
write_info() {
    touch "${FILE_INFO}"
    {
        echo "script_version=${SCRIPTS_VERSION}"
        echo "ssh_port=${SSH_PORT}"
        echo "admin_port=${RANDOM_ADMIN_PORT}"
        echo "admin_pwd=${ADMIN_TOOL_PWD}"
        echo "mysql_pwd=${sql_admin_pass}"
        echo "admin_email=${ADMIN_EMAIL}"
        echo "php1_release=yes"
        echo "php2_release=${PHP2_RELEASE}"
        echo "php1_version=${PHP_VERSION}"
        echo "php2_version=${PHP_VERSION_2}"
        echo "webserver=nginx"
        echo "lang=vi"
    } >>"${FILE_INFO}"

    touch /etc/hostvn.lock
    chmod 600 "${FILE_INFO}" /etc/hostvn.lock

    if [[ ! -f "/var/hostvn/ipaddress" ]]; then
        cat >>"/var/hostvn/ipaddress" <<END
#!/bin/bash
IPADDRESS=${IPADDRESS}
END
    fi
}

open_port() {
    systemctl start ufw
    systemctl enable ufw
    ufw enable << EOF
y
EOF

    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 20/tcp
    ufw allow 21/tcp
    ufw allow 25/tcp
    ufw allow 53/tcp
    ufw allow 110/tcp
    ufw allow 143/tcp
    ufw allow 993/tcp
    ufw allow 995/tcp
    ufw allow 9200/tcp
    ufw allow 9300/tcp
    ufw allow 465/tcp
    ufw allow 587/tcp
    ufw allow "${RANDOM_ADMIN_PORT}"/tcp

    ufw allow 20/udp
    ufw allow 21/udp

    if [[ "$prompt_ssh" =~ ^([yY]) ]]; then
        ufw allow 8282/tcp
    fi

    systemctl restart ufw
}

kernel_tweak(){
    mv /etc/sysctl.conf /etc/sysctl.conf."$(date +%Y-%m-%d)"
    cat >> "/etc/sysctl.conf" << EOsysctl
###
### GENERAL SYSTEM SECURITY OPTIONS ###
###

# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0

# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1

#Allow for more PIDs
kernel.pid_max = 65535

# The contents of /proc/<pid>/maps and smaps files are only visible to
# readers that are allowed to ptrace() the process
#kernel.maps_protect = 1

#Enable ExecShield protection
#kernel.exec-shield = 1
kernel.randomize_va_space = 2

# Controls the maximum size of a message, in bytes
kernel.msgmnb = 65535

# Controls the default maxmimum size of a mesage queue
kernel.msgmax = 65535

# Restrict core dumps
fs.suid_dumpable = 0

# Hide exposed kernel pointers
kernel.kptr_restrict = 1

###
### IMPROVE SYSTEM MEMORY MANAGEMENT ###
###

# Increase size of file handles and inode cache
fs.file-max = 209708

# Do less swapping
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure=50

# specifies the minimum virtual address that a process is allowed to mmap
vm.mmap_min_addr = 4096

# 50% overcommitment of available memory
vm.overcommit_ratio = 50
vm.overcommit_memory = 0

# Set maximum amount of memory allocated to shm to 256MB
kernel.shmmax = 268435456
kernel.shmall = 268435456

# Keep at least 64MB of free RAM space available
vm.min_free_kbytes = 65535

###
### GENERAL NETWORK SECURITY OPTIONS ###
###

#Prevent SYN attack, enable SYNcookies (they will kick-in when the max_syn_backlog reached)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096

# Disables packet forwarding
net.ipv4.ip_forward = 0
net.ipv4.conf.all.forwarding = 0
net.ipv4.conf.default.forwarding = 0
net.ipv6.conf.all.forwarding = 0
net.ipv6.conf.default.forwarding = 0

# Disables IP source routing
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Enable IP spoofing protection, turn on source route verification
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable ICMP Redirect Acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Enable Log Spoofed Packets, Source Routed Packets, Redirect Packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Decrease the time default value for tcp_fin_timeout connection
net.ipv4.tcp_fin_timeout = 7

# Decrease the time default value for connections to keep alive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Don't relay bootp
net.ipv4.conf.all.bootp_relay = 0

# Don't proxy arp for anyone
net.ipv4.conf.all.proxy_arp = 0

# Turn on the tcp_timestamps, accurate timestamp make TCP congestion control algorithms work better
net.ipv4.tcp_timestamps = 1

# Don't ignore directed pings
net.ipv4.icmp_echo_ignore_all = 0

# Enable ignoring broadcasts request
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Enable bad error message Protection
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Allowed local port range
net.ipv4.ip_local_port_range = 16384 65535

# Enable a fix for RFC1337 - time-wait assassination hazards in TCP
net.ipv4.tcp_rfc1337 = 1

# Do not auto-configure IPv6
#net.ipv6.conf.all.autoconf=0
#net.ipv6.conf.all.accept_ra=0
#net.ipv6.conf.default.autoconf=0
#net.ipv6.conf.default.accept_ra=0
#net.ipv6.conf.eth0.autoconf=0
#net.ipv6.conf.eth0.accept_ra=0

###
### TUNING NETWORK PERFORMANCE ###
###

# Use BBR TCP congestion control and set tcp_notsent_lowat to 16384 to ensure HTTP/2 prioritization works optimally
# Do a 'modprobe tcp_bbr' first (kernel > 4.9)
# Fall-back to htcp if bbr is unavailable (older kernels)
net.ipv4.tcp_congestion_control = htcp
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384

# For servers with tcp-heavy workloads, enable 'fq' queue management scheduler (kernel > 3.12)
net.core.default_qdisc = fq

# Turn on the tcp_window_scaling
net.ipv4.tcp_window_scaling = 1

# Increase the read-buffer space allocatable
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384
net.core.rmem_default = 262144
net.core.rmem_max = 16777216

# Increase the write-buffer-space allocatable
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# Increase number of incoming connections
net.core.somaxconn = 32768

# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 16384
net.core.dev_weight = 64

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 65535

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 1440000

# try to reuse time-wait connections, but don't recycle them (recycle can break clients behind NAT)
#net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1

# Limit number of orphans, each orphan can eat up to 16M (max wmem) of unswappable memory
net.ipv4.tcp_max_orphans = 16384
net.ipv4.tcp_orphan_retries = 0

# Limit the maximum memory used to reassemble IP fragments (CVE-2018-5391)
net.ipv4.ipfrag_low_thresh = 196608
net.ipv6.ip6frag_low_thresh = 196608
net.ipv4.ipfrag_high_thresh = 262144
net.ipv6.ip6frag_high_thresh = 262144

# don't cache ssthresh from previous connection
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1

# Increase size of RPC datagram queue length
net.unix.max_dgram_qlen = 50

# Don't allow the arp table to become bigger than this
net.ipv4.neigh.default.gc_thresh3 = 2048

# Tell the gc when to become aggressive with arp table cleaning.
# Adjust this based on size of the LAN. 1024 is suitable for most /24 networks
net.ipv4.neigh.default.gc_thresh2 = 1024

# Adjust where the gc will leave arp table alone - set to 32.
net.ipv4.neigh.default.gc_thresh1 = 32

# Adjust to arp table gc to clean-up more often
net.ipv4.neigh.default.gc_interval = 30

# Increase TCP queue length
net.ipv4.neigh.default.proxy_qlen = 96
net.ipv4.neigh.default.unres_qlen = 6

# Enable Explicit Congestion Notification (RFC 3168), disable it if it doesn't work for you
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_reordering = 3

# How many times to retry killing an alive TCP connection
net.ipv4.tcp_retries2 = 15
net.ipv4.tcp_retries1 = 3

# Avoid falling back to slow start after a connection goes idle
# keeps our cwnd large with the keep alive connections (kernel > 3.6)
net.ipv4.tcp_slow_start_after_idle = 0

# Allow the TCP fastopen flag to be used, beware some firewalls do not like TFO! (kernel > 3.7)
net.ipv4.tcp_fastopen = 3

# This will enusre that immediatly subsequent connections use the new values
net.ipv4.route.flush = 1
net.ipv6.route.flush = 1
EOsysctl
    sysctl -p
}

create_bash_dir
set_email
ssh_login_notify
input_ip
option_change_ssh_port
select_php_ver
select_php_multi

if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
    select_php_ver_2
    check_duplicate_php
fi

php_memory_calculation
cal_ssl_cache_size
php_parameter
mariadb_calculation
self_signed_ssl

install_nginx
install_mariadb
install_php

if [[ "${MULTI_PHP}" =~ ^(Y|y)$ ]]; then
    install_php_2
    php2_global_config
    hostvn_custom_ini_2
    php_2_opcache
    systemctl enable php"${PHP_VERSION_2}"-fpm
fi

create_nginx_conf
#_create_mod_security_config
create_wordpress_conf
create_extra_conf
default_vhost
vhost_custom
default_index
default_error_page
wp_rocket_nginx
php_global_config

systemctl enable php"${PHP_VERSION}"-fpm

hostvn_custom_ini
php_opcache
config_my_cnf

install_phpmyadmin
install_composer
install_wp_cli

install_optipng
install_jpegoptim
install_pngquant

install_acme
gen_htpasswd
opcache_dashboard
install_rclone
install_wp_cli_packages
install_fail2ban

if [[ "$prompt_ssh" =~ ^([yY]) ]]; then
    change_ssh_port
fi

setup_sftp
add_menu
write_info
open_port
kernel_tweak

clear
sleep 1

printf "=========================================================================\n"
printf "                    Cai dat thanh cong Ubuntu LEMP Stack                 \n"
printf "                 File luu thong tin: %s\n" "${FILE_INFO}"
printf "          Neu can ho tro vui long truy cap %s\n" "${AUTHOR_CONTACT}"
printf "==========================================================================\n"
printf "              Luu lai thong tin duoi day de truy cap SSH va phpMyAdmin    \n"
printf "                  ${RED}%s${NC}\n           \n" "De mo Menu su dung lenh:  hostvn"
printf "==========================================================================\n"
printf "SSH  Port                    : %s\n" "${SSH_PORT}"
printf "phpMyAdmin                   : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/phpmyadmin"
printf "Link Opcache Dashboard       : %s\n" "http://${IPADDRESS}:${RANDOM_ADMIN_PORT}/opcache"
echo "User phpMyAdmin va Admin Tool: admin                                   "
printf "Password Admin tool          : %s\n" "${ADMIN_TOOL_PWD}"
printf "Password phpMyAdmin          : %s\n" "${sql_admin_pass}"
printf "=========================================================================\n"

sleep 3
shutdown -r now
