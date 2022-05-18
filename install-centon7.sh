#!/bin/bash

######################################################################
#           Auto Install & Optimize LEMP Stack on Ubuntu/centOS      #
#                                                                    #
#                Author: Sanvv - HOSTVN Technical                    #
#                  Website: https://hostvn.vn                        #
#                                                                    #
#              Please do not remove copyright. Thank!                #
#  Please do not copy under any circumstance for commercial reason!  #
######################################################################

rm -rf install

# Set Color
RED='\033[0;31m'
NC='\033[0m'

OS=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

SCRIPT_LINK="https://scripts.hostvn.net/${OS}"
OS_LIST="centos ubuntu debian almalinux"
RAM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
LOW_RAM='400000'

# Control Panel path
CPANEL="/usr/local/cpanel/cpanel"
DIRECTADMIN="/usr/local/directadmin/custombuild/build"
PLESK="/usr/local/psa/version"
WEBMIN="/etc/init.d/webmin"
SENTORA="/root/passwords.txt"
HOCVPS="/etc/hocvps/scripts.conf"
VPSSIM="/home/vpssim.conf"
EEV3="/usr/local/bin/ee"
WORDOPS="/usr/local/bin/wo"
KUSANAGI="/home/kusanagi"
CWP="/usr/local/cwpsrv"
VESTA="/usr/local/vesta/"
EEV4="/opt/easyengine"
LARVPS="/etc/larvps/.info.conf"
TINO="/opt/tinopanel"

# Set Lang
ROOT_ERR="Ban can dang nhap SSH voi user root."
CANCEL_INSTALL="Huy cai dat..."
RAM_NOT_ENOUGH="Canh bao: Dung luong RAM qua thap de cai Script. (It nhat 512MB)"
WRONG_OS="Rat tiec he dieu hanh ban dang su dung khong duoc ho tro."
OTHER_CP_EXISTS="May chu cua ban da cai dat Control Panel khac. Vui long rebuild de cai dat Script."
HOSTVN_EXISTS="May chu cua ban da cai dat HOSTVN Script. Vui long rebuild neu muon cai dat lai."

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

create_source_list(){
    if [[ "$OS" == 'ubuntu' && "${OS_VER}" == "18.04" ]]; then
        mv /etc/apt/sources.list /etc/apt/sources.list."$(date +%Y-%m-%d)"
        cat >> "/etc/apt/sources.list" << EOsource_list
deb http://archive.ubuntu.com/ubuntu/ bionic main restricted
deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ bionic universe
deb http://archive.ubuntu.com/ubuntu/ bionic-updates universe
deb http://archive.ubuntu.com/ubuntu/ bionic multiverse
deb http://archive.ubuntu.com/ubuntu/ bionic-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu bionic-security main restricted
deb http://security.ubuntu.com/ubuntu bionic-security universe
deb http://security.ubuntu.com/ubuntu bionic-security multiverse
EOsource_list

        apt update -y
    fi
    if [[ "$OS" == 'ubuntu' && "${OS_VER}" == "20.04" ]]; then
        mv /etc/apt/sources.list /etc/apt/sources.list."$(date +%Y-%m-%d)"
        cat >> "/etc/apt/sources.list" << EOsource_list
deb http://archive.ubuntu.com/ubuntu/ focal main restricted
deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ focal universe
deb http://archive.ubuntu.com/ubuntu/ focal-updates universe
deb http://archive.ubuntu.com/ubuntu/ focal-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ focal multiverse
deb http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu focal-security main restricted
deb http://security.ubuntu.com/ubuntu focal-security universe
deb http://security.ubuntu.com/ubuntu focal-security multiverse
EOsource_list

        apt update -y
    fi
}

if [[ "$(id -u)" != "0" ]]; then
    printf "${RED}%s${NC}\n" "${ROOT_ERR}"
    printf "${RED}%s${NC}\n" "${CANCEL_INSTALL}"
    exit
fi

if [[ ${RAM_TOTAL} -lt ${LOW_RAM} ]]; then
    printf "${RED}%s${NC}\n" "${RAM_NOT_ENOUGH}"
    printf "${RED}%s${NC}\n" "${CANCEL_INSTALL}"
    exit
fi

if [[ -f "${CPANEL}" || -f "${DIRECTADMIN}" || -f "${PLESK}" || -f "${WEBMIN}" || -f "${SENTORA}" || -f "${HOCVPS}" || -f "${LARVPS}" ]]; then
    printf "${RED}%s${NC}\n" "${OTHER_CP_EXISTS}"
    printf "${RED}%s${NC}\n" "${CANCEL_INSTALL}"
    exit
fi

if [[ -f "${VPSSIM}" || -f "${WORDOPS}" || -f "${EEV3}" || -d "${EEV4}" || -d "${VESTA}" || -d "${CWP}" || -d "${KUSANAGI}" || -d "${TINO}" ]]; then
    printf "${RED}%s${NC}\n" "${OTHER_CP_EXISTS}"
    printf "${RED}%s${NC}\n" "${CANCEL_INSTALL}"
    exit
fi

if [[ -f "/var/hostvn/.hostvn.conf" ]]; then
    printf "${RED}%s${NC}\n" "${HOSTVN_EXISTS}"
    printf "${RED}%s${NC}\n" "${CANCEL_INSTALL}"
    exit
fi

OS_VER=$(grep -w "VERSION_ID=" "/etc/os-release" | cut -f2 -d'=' | cut -f2 -d'"')

# if [ ${OS_VER} == '8' ]; then
#     printf "${RED}%s${NC}\n" "Hien tai centOS 8 da khong con duoc cong ty RHEL ho tro phat trien phien ban on dinh. Vui long su dung phien ban Ubuntu 18.04 hoac 20.04"
#     printf "%s\n" "${RED}De biet them thong tin ban co the search Google voi tu khoa:${NC} centOS is Dead"
#     printf "${RED}%s${NC}\n" "Huy cai dat."
#     exit 0
# fi

if [[ " ${OS_LIST[*]} " == *" ${OS} "* ]]; then
    prompt_install="y"
    if [[ "${OS}" == "centos" ]]; then
        printf "${RED}%s${NC}\n" "Hien tai centOS da khong con duoc cong ty RHEL ho tro phat trien phien ban on dinh."
        printf "%s\n" "${RED}De biet them thong tin ban co the search Google voi tu khoa:${NC} centOS is Dead"
        printf "${RED}%s${NC}\n" "De VPS hoat dong on dinh khuyen nghi ban nen cai dat ban Ubuntu (18.04, 20.04) thay vi su dung ban centOS."
        printf "%s\n" "${RED}Huy cai dat.${NC}"
        exit

        # while true
        # do
        #     read -r -p "Ban co muon tiep tuc cai dat khong ? (y/n) " prompt_install
        #     echo
        #     if [[ "${prompt_install}" =~ ^([yY])$ || "${prompt_install}" =~ ^([nN])$ ]]; then
        #         break
        #     else
        #         printf "%s\n" "${RED}Huy cai dat.${NC}"
        #         exit
        #     fi
        # done
    fi

    if [[ "${prompt_install}" =~ ^([yY])$ ]]; then
        if [[ "${OS}" == "centos" || "${OS}" == "almalinux" ]]; then
            yum -y update
            yum -y install dos2unix
        else
            create_source_list
            apt autoremove -y
            apt -y install dos2unix
        fi
        curl -sO "${SCRIPT_LINK}"/"${OS}"
		cp "${OS}" /home/ossss
		echo "1-${OS}" >> /root/os.txt
        dos2unix "${OS}"
		echo "2-${OS}" >> /root/os.txt
        chmod +x "${OS}"
		echo "3-${OS}" >> /root/os.txt
		cp "${OS}"
        bash "${OS}"
		echo "4-${OS}" >> /root/os.txt
    fi
else
    printf "${RED}%s${NC}\n" "${WRONG_OS}"
    printf "${RED}%s${NC}\n" "${CANCEL_INSTALL}"
    exit
fi
