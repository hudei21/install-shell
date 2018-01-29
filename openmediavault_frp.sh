#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:   Debian(32bit/64bit)
#   Description:  A tool to auto-compile & install frpc on Linux
#   Author: mr.peng
#   Intro:  
#===============================================================================================
program_name="frp"
version="1.8.1"
str_program_dir="/usr/local/bin/${program_name}"
github_download_url="https://github.com/fatedier/frp/releases/download"
program_version="0.15.1"
program_init="/etc/init.d/frpc"
program_config_file="frpc.conf"
program_init_download_url=https://raw.githubusercontent.com/hudei21/openmediavault-frp/master/etc/init.d/frpc
str_install_shell=https://raw.githubusercontent.com/hudei21/install-shell/master/openmediavault_frp.sh

shell_update(){
    echo "Check updates for shell..."
    remote_shell_version=`wget --no-check-certificate -qO- ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
    if [ ! -z ${remote_shell_version} ]; then
        if [[ "${version}" != "${remote_shell_version}" ]];then
            echo -e "${COLOR_GREEN}Found a new version,update now!!!${COLOR_END}"
            echo
            echo -n "Update shell ..."
            if ! wget --no-check-certificate -qO $0 ${str_install_shell}; then
                echo -e " [${COLOR_RED}failed${COLOR_END}]"
                echo
                exit 1
            else
                echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
                echo
                echo -e "${COLOR_GREEN}Please Re-run${COLOR_END} ${COLOR_PINK}$0 ${clang_action}${COLOR_END}"
                echo
                exit 1
            fi
            exit 1
        fi
    fi
}

fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}
# Check if user is root
rootness(){
    if [[ $EUID -ne 0 ]]; then
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}


# Check OS bit 检查系统32/64位
check_os_bit(){
    ARCHS=""
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCHS="amd64"
    else
        Is_64bit='n'
        ARCHS="386"
    fi
}

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}
pre_install_packs(){
    local wget_flag=''
    local killall_flag=''
    local netstat_flag=''
    wget --version > /dev/null 2>&1
    wget_flag=$?
    killall -V >/dev/null 2>&1
    killall_flag=$?
    netstat --version >/dev/null 2>&1
    netstat_flag=$?
    if [[ ${wget_flag} -gt 1 ]] || [[ ${killall_flag} -gt 1 ]] || [[ ${netstat_flag} -gt 6 ]];then
        echo -e "${COLOR_GREEN} Install support packs...${COLOR_END}"
        apt-get -y update && apt-get -y install wget psmisc net-tools
    fi
}
# Random password
fun_randstr(){
    strNum=$1
    [ -z "${strNum}" ] && strNum="16"
    strRandomPass=""
    strRandomPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w ${strNum} | head -n1`
    echo ${strRandomPass}
}
fun_getServer(){
    def_server_url="aliyun"
    echo ""
    echo -e "Please select ${program_name} download url:"
    echo -e "[1].aliyun (default)"
    echo -e "[2].github"
    read -p "Enter your choice (1, 2 or exit. default [${def_server_url}]): " set_server_url
    [ -z "${set_server_url}" ] && set_server_url="${def_server_url}"
    case "${set_server_url}" in
        1|[Aa][Ll][Ii][Yy][Uu][Nn])
            program_download_url=${aliyun_download_url}
            ;;
        2|[Gg][Ii][Tt][Hh][Uu][Bb])
            program_download_url=${github_download_url}
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            program_download_url=${github_download_url}
            ;;
    esac
    echo "---------------------------------------"
    echo "Your select: ${set_server_url}"
    echo "---------------------------------------"
}
fun_getVer(){
    echo -e "Loading network version for ${program_name}, please wait..."
    program_latest_filename="frp_${program_version}_linux_${ARCHS}.tar.gz"
    program_latest_file_url="${program_download_url}/v${program_version}/${program_latest_filename}"
    if [ -z "${program_latest_filename}" ]; then
        echo -e "${COLOR_RED}Load network version failed!!!${COLOR_END}"
    else
        echo -e "${program_name} Latest release file ${COLOR_GREEN}${program_latest_filename}${COLOR_END}"
    fi
}
fun_download_file(){
    # download
    if [ ! -s ${str_program_dir}/${program_name} ]; then
        rm -fr ${program_latest_filename} frp_${program_version}_linux_${ARCHS}
        if ! wget --no-check-certificate -q ${program_latest_file_url} -O ${program_latest_filename}; then
            echo -e " ${COLOR_RED}failed${COLOR_END}"
            exit 1
        fi
        tar xzf ${program_latest_filename}
        mv frp_${program_version}_linux_${ARCHS}/frpc ${str_program_dir}/${program_name}
        rm -fr ${program_latest_filename} frp_${program_version}_linux_${ARCHS}
    fi
    chown root:root -R ${str_program_dir}
    if [ -s ${str_program_dir}/${program_name} ]; then
        [ ! -x ${str_program_dir}/${program_name} ] && chmod 755 ${str_program_dir}/${program_name}
    else
        echo -e " ${COLOR_RED}failed${COLOR_END}"
        exit 1
    fi
}
function __readINI() {
 INIFILE=$1; SECTION=$2; ITEM=$3
 _readIni=`awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE`
echo ${_readIni}
}
# Check port
fun_check_port(){
    port_flag=""
    strCheckPort=""
    input_port=""
    port_flag="$1"
    strCheckPort="$2"
    if [ ${strCheckPort} -ge 1 ] && [ ${strCheckPort} -le 65535 ]; then
        checkServerPort=`netstat -ntulp | grep "\b:${strCheckPort}\b"`
        if [ -n "${checkServerPort}" ]; then
            echo ""
            echo -e "${COLOR_RED}Error:${COLOR_END} Port ${COLOR_GREEN}${strCheckPort}${COLOR_END} is ${COLOR_PINK}used${COLOR_END},view relevant port:"
            netstat -ntulp | grep "\b:${strCheckPort}\b"
            fun_input_${port_flag}_port
        else
            input_port="${strCheckPort}"
        fi
    else
        echo "Input error! Please input correct numbers."
        fun_input_${port_flag}_port
    fi
}
fun_check_number(){
    num_flag=""
    strMaxNum=""
    strCheckNum=""
    input_number=""
    num_flag="$1"
    strMaxNum="$2"
    strCheckNum="$3"
    if [ ${strCheckNum} -ge 1 ] && [ ${strCheckNum} -le ${strMaxNum} ]; then
        input_number="${strCheckNum}"
    else
        echo "Input error! Please input correct numbers."
        fun_input_${num_flag}
    fi
}
# input port




fun_input_log_max_days(){
    def_max_days="30"
    def_log_max_days="3"
    echo ""
    echo -e "Please input ${program_name} ${COLOR_GREEN}log_max_days${COLOR_END} [1-${def_max_days}]"
    read -p "(Default log_max_days: ${def_log_max_days} day):" input_log_max_days
    [ -z "${input_log_max_days}" ] && input_log_max_days="${def_log_max_days}"
    fun_check_number "log_max_days" "${def_max_days}" "${input_log_max_days}"
}

omv_frp_install(){
    echo -e "Check your server setting, please wait..."
    disable_selinux
    if [ -s ${str_program_dir}/${program_name} ] && [ -s ${program_init} ]; then
        echo "${program_name} is installed!"
    else
        clear
        fun_getServer
        fun_getVer
        echo -e "Loading You Server IP, please wait..."
        defIP=$(wget -qO- ip.clang.cn | sed -r 's/\r//')
        echo -e "You Server IP:${COLOR_GREEN}${defIP}${COLOR_END}"
        echo -e  "${COLOR_YELOW}Please input your server setting:${COLOR_END}"


        def_dashboard_user="admin"
        read -p "Please input dashboard_user (Default: ${def_dashboard_user}):" set_dashboard_user
        [ -z "${set_dashboard_user}" ] && set_dashboard_user="${def_dashboard_user}"
        echo "${program_name} dashboard_user: ${set_dashboard_user}"
        echo ""
        def_dashboard_pwd=`fun_randstr 8`
        read -p "Please input dashboard_pwd (Default: ${def_dashboard_pwd}):" set_dashboard_pwd
        [ -z "${set_dashboard_pwd}" ] && set_dashboard_pwd="${def_dashboard_pwd}"
        echo "${program_name} dashboard_pwd: ${set_dashboard_pwd}"
        echo ""
        default_privilege_token=`fun_randstr 16`
        read -p "Please input privilege_token (Default: ${default_privilege_token}):" set_privilege_token
        [ -z "${set_privilege_token}" ] && set_privilege_token="${default_privilege_token}"
        echo "${program_name} privilege_token: ${set_privilege_token}"
        echo ""

        echo ""
        echo "##### Please select log_level #####"
        echo "1: info (default)"
        echo "2: warn"
        echo "3: error"
        echo "4: debug"
        echo "#####################################################"
        read -p "Enter your choice (1, 2, 3, 4 or exit. default [1]): " str_log_level
        case "${str_log_level}" in
            1|[Ii][Nn][Ff][Oo])
                str_log_level="info"
                ;;
            2|[Ww][Aa][Rr][Nn])
                str_log_level="warn"
                ;;
            3|[Ee][Rr][Rr][Oo][Rr])
                str_log_level="error"
                ;;
            4|[Dd][Ee][Bb][Uu][Gg])
                str_log_level="debug"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                str_log_level="info"
                ;;
        esac
        echo "log_level: ${str_log_level}"
        echo ""
        fun_input_log_max_days
        [ -n "${input_number}" ] && set_log_max_days="${input_number}"
        echo "${program_name} log_max_days: ${set_log_max_days}"
        echo ""
        echo "##### Please select log_file #####"
        echo "1: enable (default)"
        echo "2: disable"
        echo "#####################################################"
        read -p "Enter your choice (1, 2 or exit. default [1]): " str_log_file
        case "${str_log_file}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                str_log_file="./frps.log"
                str_log_file_flag="enable"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                str_log_file="/dev/null"
                str_log_file_flag="disable"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                str_log_file="./frps.log"
                str_log_file_flag="enable"
                ;;
        esac
        echo "log_file: ${str_log_file_flag}"
        echo ""
        echo "##### Please select tcp_mux #####"
        echo "1: enable (default)"
        echo "2: disable"
        echo "#####################################################"
        read -p "Enter your choice (1, 2 or exit. default [1]): " str_tcp_mux
        case "${str_tcp_mux}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                set_tcp_mux="true"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                set_tcp_mux="false"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                set_tcp_mux="true"
                ;;
        esac
        echo "tcp_mux: ${set_tcp_mux}"
        echo ""
        echo "##### Please select kcp support #####"
        echo "1: enable (default)"
        echo "2: disable"
        echo "#####################################################"
        read -p "Enter your choice (1, 2 or exit. default [1]): " str_kcp
        case "${str_kcp}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                set_kcp="true"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                set_kcp="false"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                set_kcp="true"
                ;;
        esac
        echo "kcp support: ${set_kcp}"
        echo ""
        echo ""
        echo "Press any key to start...or Press Ctrl+c to cancel"

        char=`get_char`
        install_program_client
    fi
}
# ====== install server ======
install_program_client(){
    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo "${program_name} install path:$PWD"

    echo -n "config file for ${program_name} ..."
# Config file
if [[ "${set_kcp}" == "false" ]]; then 
cat > ${str_program_dir}/${program_config_file}<<-EOF
# [common] is integral section
[common]
# A literal address or host name for IPv6 must be enclosed
# in square brackets, as in "[::1]:80", "[ipv6-host]:http" or "[ipv6-host%zone]:80"
bind_addr = 0.0.0.0
bind_port = ${set_bind_port}
# udp port used for kcp protocol, it can be same with 'bind_port'
# if not set, kcp is disabled in frps
#kcp_bind_port = ${set_bind_port}
# if you want to configure or reload frps by dashboard, dashboard_port must be set
dashboard_port = ${set_dashboard_port}
# dashboard assets directory(only for debug mode)
dashboard_user = ${set_dashboard_user}
dashboard_pwd = ${set_dashboard_pwd}
# assets_dir = ./static

vhost_http_port = ${set_vhost_http_port}

# console or real logFile path like ./frps.log
log_file = ${str_log_file}
# debug, info, warn, error
log_level = ${str_log_level}
log_max_days = ${set_log_max_days}
# privilege mode is the only supported mode since v0.10.0
privilege_token = ${set_privilege_token}
# only allow frpc to bind ports you list, if you set nothing, there won't be any limit
#privilege_allow_ports = 1-65535
# pool_count in each proxy will change to max_pool_count if they exceed the maximum value
max_pool_count = ${set_max_pool_count}
# if tcp stream multiplexing is used, default is true
tcp_mux = ${set_tcp_mux}

EOF
else
cat > ${str_program_dir}/${program_config_file}<<-EOF
# [common] is integral section
[common]
# A literal address or host name for IPv6 must be enclosed
# in square brackets, as in "[::1]:80", "[ipv6-host]:http" or "[ipv6-host%zone]:80"
bind_addr = 0.0.0.0
bind_port = ${set_bind_port}
# udp port used for kcp protocol, it can be same with 'bind_port'
# if not set, kcp is disabled in frps
kcp_bind_port = ${set_bind_port}
# if you want to configure or reload frps by dashboard, dashboard_port must be set
dashboard_port = ${set_dashboard_port}
# dashboard assets directory(only for debug mode)
dashboard_user = ${set_dashboard_user}
dashboard_pwd = ${set_dashboard_pwd}
# assets_dir = ./static

vhost_http_port = ${set_vhost_http_port}

# console or real logFile path like ./frps.log
log_file = ${str_log_file}
# debug, info, warn, error
log_level = ${str_log_level}
log_max_days = ${set_log_max_days}
# privilege mode is the only supported mode since v0.10.0
privilege_token = ${set_privilege_token}
# only allow frpc to bind ports you list, if you set nothing, there won't be any limit
#privilege_allow_ports = 1-65535
# pool_count in each proxy will change to max_pool_count if they exceed the maximum value
max_pool_count = ${set_max_pool_count}
# if tcp stream multiplexing is used, default is true
tcp_mux = ${set_tcp_mux}

EOF
fi
    echo " done"

    echo -n "download ${program_name} ..."
    rm -f ${str_program_dir}/${program_name} ${program_init}
    fun_download_file
    echo " done"
    echo -n "download ${program_init}..."
    if [ ! -s ${program_init} ]; then
        if ! wget --no-check-certificate -q ${program_init_download_url} -O ${program_init}; then
            echo -e " ${COLOR_RED}failed${COLOR_END}"
            exit 1
        fi
    fi
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    echo " done"

    echo -n "setting ${program_name} boot..."
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    if [ "${OS}" == 'CentOS' ]; then
        chmod +x ${program_init}
        chkconfig --add ${program_name}
    else
        chmod +x ${program_init}
        update-rc.d -f ${program_name} defaults
    fi
    echo " done"
    [ -s ${program_init} ] && ln -s ${program_init} /usr/bin/${program_name}
    ${program_init} start

    #install successfully
    echo ""
    echo "Congratulations, ${program_name} install completed!"
    echo "=============================================="
    exit 0
}
############################### configure ##################################
configure_program_server(){
    if [ -s ${str_program_dir}/${program_config_file} ]; then
        vi ${str_program_dir}/${program_config_file}
    else
        echo "${program_name} configuration file not found!"
        exit 1
    fi
}
############################### uninstall ##################################
uninstall_program_server(){
    if [ -s ${program_init} ] || [ -s ${str_program_dir}/${program_name} ] ; then
        echo "============== Uninstall ${program_name} =============="
        str_uninstall="n"
        echo -n -e "${COLOR_YELOW}You want to uninstall?${COLOR_END}"
        read -p "[y/N]:" str_uninstall
        case "${str_uninstall}" in
        [yY]|[yY][eE][sS])
        echo ""
        echo "You select [Yes], press any key to continue."
        str_uninstall="y"
        char=`get_char`
        ;;
        *)
        echo ""
        str_uninstall="n"
        esac
        if [ "${str_uninstall}" == 'n' ]; then
            echo "You select [No],shell exit!"
        else

            ${program_init} stop
            if [ "${OS}" == 'CentOS' ]; then
                chkconfig --del ${program_name}
            else
                update-rc.d -f ${program_name} remove
            fi
            rm -f ${program_init} /var/run/${program_name}.pid /usr/bin/${program_name}
            rm -fr ${str_program_dir}
            echo "${program_name} uninstall success!"
        fi
    else
        echo "${program_name} Not install!"
    fi
    exit 0
}
############################### update ##################################

update_program_server(){
    if [ -s ${program_init} ] || [ -s ${str_program_dir}/${program_name} ] ; then
        echo "============== Update ${program_name} =============="
        check_os_bit
        remote_init_version=`wget --no-check-certificate -qO- ${program_init_download_url} | sed -n '/'^version'/p' | cut -d\" -f2`
        local_init_version=`sed -n '/'^version'/p' ${program_init} | cut -d\" -f2`
        install_shell=${strPath}
        if [ ! -z ${remote_init_version} ];then
            if [[ "${local_init_version}" != "${remote_init_version}" ]];then
                echo "========== Update ${program_name} ${program_init} =========="
                if ! wget --no-check-certificate ${program_init_download_url} -O ${program_init}; then
                    echo "Failed to download ${program_name}.init file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}${program_init} Update successfully !!!${COLOR_END}"
                fi
            fi
        fi
        [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
        echo -e "Loading network version for ${program_name}, please wait..."
        fun_getServer
        fun_getVer >/dev/null 2>&1
        local_program_version=`${str_program_dir}/${program_name} --version`
        echo -e "${COLOR_GREEN}${program_name}  local version ${local_program_version}${COLOR_END}"
        echo -e "${COLOR_GREEN}${program_name} remote version ${program_version}${COLOR_END}"
        if [[ "${local_program_version}" != "${program_version}" ]];then
            echo -e "${COLOR_GREEN}Found a new version,update now!!!${COLOR_END}"
            ${program_init} stop
            sleep 1
            rm -f /usr/bin/${program_name} ${str_program_dir}/${program_name}
            fun_download_file
            if [ "${OS}" == 'CentOS' ]; then
                chmod +x ${program_init}
                chkconfig --add ${program_name}
            else
                chmod +x ${program_init}
                update-rc.d -f ${program_name} defaults
            fi
            [ -s ${program_init} ] && ln -s ${program_init} /usr/bin/${program_name}
            [ ! -x ${program_init} ] && chmod 755 ${program_init}
            ${program_init} start
            echo "${program_name} version `${str_program_dir}/${program_name} --version`"
            echo "${program_name} update success!"
        else
                echo -e "no need to update !!!${COLOR_END}"
        fi
    else
        echo "${program_name} Not install!"
    fi
    exit 0
}
clear
strPath=`pwd`
rootness
fun_set_text_color
check_os_bit
pre_install_packs
shell_update

# Initialization
action=$1
[  -z $1 ]
case "$action" in
install)
    omv_frp_install 2>&1 | tee /root/openmediavault_${program_name}-install.log
    ;;
uninstall)
    uninstall_program_server 2>&1 | tee /root/openmediavault_${program_name}-uninstall.log
    ;;
update)
    update_program_server 2>&1 | tee /root/openmediavault_${program_name}-update.log
    ;;
config)
    configure_program_server
    ;;	
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update|config}"
    RET_VAL=1
    ;;
esac
