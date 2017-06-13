#!/usr/bin/env bash
#
# Name: Setup GNU/Linux machine to Projeto Pescar Procempa
# Author: Jonatha Daguerre Vasconcelos <jonatha@daguerre.com.br>
# Version: 3.3 (12 Jun 2017)
# License: MIT
#
#
#
#                  DESCRIPTION
#
# This script sets up the Projeto Pescar Procempa's machines
# in order to avoid the students to do that in their first class.
#
# Customized to Linux Mint 18. 
#
# This script should:
# - Set HTTP_PROXY variables.
# - Set apt-get proxy.
# - Install Open SSH Server.
# - Update/Install some packages.
# - Update Firefox profile.
#
#              CHANGE HISTORY
# 3.3 (12 Jun 2017) - Changes license from GPL to MIT. Changed size of Zenity window
# 3.2 (11 Jun 2017) - Improving log messages and updating script to support Mint 18
# 3.1.1 (05 Jun 2016) - Removed Proxy information (in order to public the source)
# 3.1 (05 Jun 2016) - Added again the functions to set proxy to Firefox and Chormium. Added Zenity to display the options sbox
# 3.0 (25 May 2016) - Refectored all functions. Removed functions to set proxy to Firefox and Chormium
# 2.0 (20 May 2015) - Recreated the functions to set proxy to browsers and added its options to menu
# 1.3 (15 May 2015) - Fixed double execution error when executing sudo via 'sudo -S'
# 1.2 (14 May 2015) - Fixed error in some functions and improved them as well
# 1.1 (14 May 2015) - Added dialog as default UI
# 1.0 (08 Jun 2014) - First version
#
# TODO (jonathadv): Define a better way to present messages, choose one lang only.
# FIXME (jonathadv): Improve the way to get BASE_DIR, avoiding the "./" to be used.
#

# Setting up the global variables
declare -r THIS_SCRIPT_PATH="${0}"
declare -r BASE_DIR="$(dirname ${THIS_SCRIPT_PATH})"
declare -r PROPERTIES_FILE='setup_pescar_machine.properties'

# pt-BR messages
declare -r MESSAGE_SETTING_USER_PROFILE='Configurando proxy para o usuário'
declare -r MESSAGE_PROXY_CONFIGURED='Proxy configurado!'
declare -r MESSAGE_OPEN_LOG_FILE='Abrindo arquivo de log...'
declare -r MESSAGE_ENTER_PASSWORD="Digite sua senha para o usuário"
declare -r MESSAGE_CONF_PROXY_APT="Configurando Proxy para APT"
declare -r MESSAGE_UPDATING_CONFIG='Atualizando configurações'

declare -r DIALOG_TITLE='Configuração Pescar Procempa'
declare -r DIALOG_OPTIONS='Opções'
declare -r DIALOG_OPT_PROXY_SYSTEM='Proxy_Sistema'
declare -r DIALOG_OPT_PROXY_APT='Proxy_APT'
declare -r DIALOG_OPT_BROWSER_PROXY='Proxy_Browsers'
declare -r DIALOG_OPT_UPDATE='Atualizar_Sistema'

# Proxy variables
declare    PROXY_URL=''
declare    PROXY_PORT=''
declare    NO_PROXY=''
declare    PROXY='' #"$PROXY_URL:$PROXY_PORT"

# Temp log file definition
declare -r TMP_LOG_FILE="/tmp/pescar_tmp_$(date +%s).log"

# Default Pescar User Password
declare -r PESCAR_DEFAULT_PASSWORD='pescar'

# File-Flag to avoid script to run twice
declare -r IT_HAS_RUN='/tmp/it_has_run'

# Flag to prevent apt-get update to be run more than once
APT_GET_UPDATE=1


#######################################
# Log the messages in a tmp file and
# send them to stdout.
# Globals:
#   TMP_LOG_FILE
# Arguments:
#   The String value to be logged
# Returns:
#   None
#######################################
function logger(){
    echo -en "$(date) - ${FUNCNAME[1]}(): ${*}\n" | tee -a "${TMP_LOG_FILE}"
}


#######################################
# Prints a pretty header to titles
# Globals:
#   None
# Arguments:
#   The String title to be displayed
# Returns:
#   None
#######################################
function print_header(){
    local phrase="${*}"
    local length=$((${#phrase}+2))
    local header=''

    for i in $(seq ${length}); do
        header="${header}-"
    done

    header="\n+${header}+\n| ${phrase} |\n+${header}+\n\n"

    echo -en "${header}"
}


#######################################
# Prints a simple line
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function print_line(){
    echo '----------------------------------------------------------------------'
}


#######################################
# Creates a backup for a file sent as
# argument.
# Globals:
#   TMP_LOG_FILE
# Arguments:
#   File path
# Returns:
#   Exit Code of cp command
#######################################
function backup(){
    local file="${1}"
	local backup_name="${file}.bkp.$(date +%s)"
    local exit_code=2

    logger "Creating backup for ${file}"

    if [[ -f "${file}" ]]; then
        cp -f "${file}" "${backup_name}" | tee -a "${TMP_LOG_FILE}"
        exit_code="$?"

    elif [[ -d "${file}" ]]; then
        cp -Rf "${file}" "${backup_name}" | tee -a "${TMP_LOG_FILE}"
        exit_code="$?"

    else
        logger "\"${file}\" does not seem to be a file or directory. Nothing to do."
        exit_code=1
    fi

    return ${exit_code}
}

#######################################
# Check empty variables
# Globals:
#   None
# Arguments:
#   name: The variable name
#   value: The variable value
# Returns:
#   None
#######################################
function check_empty(){
    local name="${1}"
    local value="${2}"
    
    if [[ -z "${value}" ]]; then
        logger "Variable ${name} is empty! Exiting script."
        exit 1
    fi
}

#######################################
# Read property file
# Globals:
#   BASE_DIR
#   PROXY_URL
#   PROXY_PORT
#   PROXY
#   PROPERTIES_FILE
# Arguments:
#   None
# Returns:
#   None
#######################################
function load_properties_file(){
    local prop_file="${BASE_DIR}/${PROPERTIES_FILE}"
    
    logger "Loading properties file: ${prop_file}"
    
    if [[ ! -f "${prop_file}" ]]; then
        logger "Propeties file ${prop_file} not found! Creating it with blank values."
        {
          echo '# proxy configuration'
          echo 'proxy_url='
          echo 'proxy_port='
          echo 'no_proxy='
        } > "${prop_file}"
        
    else
        source "${prop_file}"
    fi
    
        
    PROXY_URL="${proxy_url}"
    PROXY_PORT="${proxy_port}"
    NO_PROXY="${no_proxy}"
    PROXY="$PROXY_URL:$PROXY_PORT"
    
    check_empty 'PROXY_URL' "${PROXY_URL}"
    check_empty 'PROXY_PORT' "${PROXY_PORT}"
    check_empty 'NO_PROXY' "${NO_PROXY}"
    check_empty 'PROXY' "${PROXY}"
}

#######################################
# Sets the proxy server to APT
# Globals:
#   PROXY
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_proxy_to_apt(){

    local apt_configuration_file='/etc/apt/apt.conf'
    local apt_get_http_proxy_line="Acquire::http::Proxy \"$PROXY\";"
    local apt_get_ftp_proxy_line="Acquire::ftp::Proxy \"$PROXY\";"

    print_header 'Setting proxy to apt-get'

    {
        echo "${apt_get_http_proxy_line}"
        echo "${apt_get_ftp_proxy_line}"
    } > "${apt_configuration_file}"

}


#######################################
# Runs apt-get install -y
# Globals:
#   TMP_LOG_FILE
# Arguments:
#   A list of program names
# Returns:
#   None
#######################################
function run_apt_get_install(){
    local packages=( "${@}" )

    apt-get -yf --force-yes install ${packages} | tee -a "${TMP_LOG_FILE}"
}


#######################################
# Runs apt-get update and set flag to
# prevent it to be run again
# Globals:
#   APT_GET_UPDATE
#   TMP_LOG_FILE
# Arguments:
#   None
# Returns:
#   None
#######################################
function run_apt_get_update(){

    if [[ "${APT_GET_UPDATE}" == 0 ]]; then
        print_header 'Running apt-get update'
        apt-get update | tee -a "${TMP_LOG_FILE}"
        [[ "$?" == "0" ]] && APT_GET_UPDATE=1
    else
        logger 'Already up to date.'
    fi
}


#######################################
# Runs dpkg -i for all packages in cache
# Globals:
#   TMP_LOG_FILE
# Arguments:
#   None
# Returns:
#   None
#######################################

function run_dpkg_all(){
    cd '/var/cache/apt/archives'
    dpkg -i *.deb | tee -a "${TMP_LOG_FILE}"
}


#######################################
# Configure Firefox profile
# Globals:
#   BASE_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
function configure_firefox_profile(){
    local tar_file='firefox_profile.tar.gz'
    local pescar_profile='/home/pescar'
    local firefox_profile_basedir="${pescar_profile}/.mozilla/firefox"
    local default_pescar_profile_dir='default_pescar_profile'
    local current_firefox_profile_name=''
    
    cd "${BASE_DIR}"

    print_header 'Configure Firefox profile'

    if ls -d ${firefox_profile_basedir}/*.default 2> /dev/null; then
        current_firefox_profile_name=$(basename $(ls -d ${firefox_profile_basedir}/*.default))
    else
        logger "Unable to find any profile folder under \"${firefox_profile_basedir}\". Skipping profile changes."
        return 1
    fi

    backup "${firefox_profile_basedir}"

    if cp -f  "${BASE_DIR}/${tar_file}" "${firefox_profile_basedir}"; then
        cd "${firefox_profile_basedir}"
        tar -zxf "${tar_file}"
        rm -rf "${current_firefox_profile_name}"
        
        mv "${default_pescar_profile_dir}" "${current_firefox_profile_name}"
        chown -R pescar.pescar "${current_firefox_profile_name}"
        rm -f "${tar_file}"
    fi

}


#######################################
# Install some packages in the system
# Globals:
#   BASE_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
function update_system() {
    local run_apt_update=false
    local run_dpkg=false
    local apt_target_basedir='/var/cache'
    local tar_file='apt.tar'

    if grep -iq 'run-update' <<< "$@"; then
        run_apt_update=true
    fi

    if grep -iq 'run-dpkg' <<< "$@"; then
        run_dpkg=true
    fi

    print_header "Updating the system"

    backup "${apt_target_basedir}/apt"
    rm -rf "${apt_target_basedir}/apt"

    logger "Copying installation files from \"${BASE_DIR}/${tar_file}\" to \"${apt_target_basedir}\"" 
    cp -f "${BASE_DIR}/${tar_file}" "${apt_target_basedir}"
    logger 'Copy done.'

    cd "${apt_target_basedir}"
    logger "Extracting file \"${tar_file}\""
    tar -xf "${tar_file}"
    logger 'Done!'

    if ${run_dpkg}; then
        run_dpkg_all
    fi

    if ${run_apt_update}; then
       run_apt_get_update       
    fi
 
    configure_firefox_profile
 
    add_root_to_ssh

    print_line
}


#######################################
# Sets proxy to file sent as argument
# Globals:
#   PROXY
#   NO_PROXY
# Arguments:
#   File path
# Returns:
#   None
#######################################
function set_proxy_to_file(){
    local dest_file="${1}"

    if [[ ! -f "${dest_file}" ]]; then
        logger "set_proxy_to_file(): Sent at least one file as parameter"
        return 1
    fi

    print_header "Setting proxy to file: ${dest_file}"

    echo -en "\n\n\
# Proxy Configuration\n\
export http_proxy='${PROXY}'\n\
export https_proxy='${PROXY}'\n\
export ftp_proxy='${PROXY}'\n\
export no_proxy='${NO_PROXY}'\n\
export HTTP_PROXY='${PROXY}'\n\
export HTTPS_PROXY='${PROXY}'\n\
export FTP_PROXY='${PROXY}'\n\
export NO_PROXY='${NO_PROXY}'"  >> "${dest_file}"

}


#######################################
# Creates a wrapper to set proxy to Chromium
# Globals:
#   PROXY
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_proxy_to_chromium(){
  local chromium="$(which chromium-browser)"
  local chromium_bin="${chromium}-bin"

  print_header 'Set proxy to Chromium'
    
  if [[ ! -f "${chromium}" ]]; then
    logger "Chromiun Browser not found. Skipping proxy configuration."
    return 1
  fi

  backup "${chromium}"
  mv "${chromium}" "${chromium_bin}"
  
  {
      echo "#!/bin/bash"
      echo -e "\n\n"
  } >> "${chromium}"

  set_proxy_to_file "${chromium}"

  {
      echo -e "\n\n"
      echo -e "${chromium_bin} --proxy-server=${PROXY} \"\$@\" &"
      echo
  } >> "${chromium}"

  chmod 777 "${chromium}"

}


#######################################
# Sets proxy to Firefox
# Globals:
#   PROXY
#   NO_PROXY
# Arguments:
#   None
# Returns:
#   None
#######################################
set_proxy_to_firefox(){
  local firefox="$(which firefox)"
  print_header 'Set proxy to Firefox'
  backup "${firefox}"

  sed -i "2i# Proxy Configuration\n\
  export http_proxy='${PROXY}'\n\
  export https_proxy='${PROXY}'\n\
  export ftp_proxy='${PROXY}'\n\
  export no_proxy='${NO_PROXY}'\n\
  export HTTP_PROXY='${PROXY}'\n\
  export HTTPS_PROXY='${PROXY}'\n\
  export FTP_PROXY='${PROXY}'\n\
  export NO_PROXY='${NO_PROXY}'" "${firefox}"

}


#######################################
# Sets proxy env variable for the whole system
# Globals:
#   MESSAGE_PROXY_CONFIGURED
#   MESSAGE_SETTING_USER_PROFILE
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_proxy_to_env(){
    local dir_list="$(ls /home)"
    local root_bashrc='/root/.bashrc'
    local system_env='/etc/environment'

    print_header "Setting proxy to environment"

    backup "${system_env}"
    set_proxy_to_file "${system_env}"
    [ "${?}" == "0" ] && logger "$MESSAGE_PROXY_CONFIGURED"

    logger "$MESSAGE_SETTING_USER_PROFILE root..."
    backup "${root_bashrc}"
    set_proxy_to_file "${root_bashrc}"
    [ "${?}" == "0" ] && logger "$MESSAGE_PROXY_CONFIGURED"

    for dir in ${dir_list}; do
        logger "${MESSAGE_SETTING_USER_PROFILE} ${dir}..."
        backup "/home/${dir}/.bashrc"
        set_proxy_to_file "/home/${dir}/.bashrc"
        [ "${?}" == "0" ] && logger "${MESSAGE_PROXY_CONFIGURED}"
    done

    print_line

}


#######################################
# Enable SSH to root
# Globals:
#   PESCAR_DEFAULT_PASSWORD
# Arguments:
#   None
# Returns:
#   None
#######################################
function add_root_to_ssh(){
    local sshd_config_file="/etc/ssh/sshd_config"
    local string_to_replace="PermitRootLogin without-password"
    local cmd_tmp_file="$(tempfile)"

    if [ -f "${sshd_config_file}" ]; then
        backup "${sshd_config_file}"
        sed -i "s/${string_to_replace}/#${string_to_replace}/" "${sshd_config_file}"
        [[ "${?}" == "0" ]] && logger "SSH Root login enabled!"

    else
        logger "File ${sshd_config_file} not found!"
    fi



    logger "Setting root password..."
    echo "echo \"root:${PESCAR_DEFAULT_PASSWORD}\" | chpasswd" > "${cmd_tmp_file}"
    chmod +x "${cmd_tmp_file}"

    if (sudo -S "${cmd_tmp_file}" <<< "${PESCAR_DEFAULT_PASSWORD}" 2> /dev/null); then
        logger "Root password set!"
    else
        logger "Root password NOT set!"
    fi

    rm -f "${cmd_tmp_file}"

    logger "Done!"

    print_line

}


#######################################
# Installs and starts ssh server
# Globals:
#   TMP_LOG_FILE
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_ssh_server(){
    print_header "Install Open SSH Server"

    if [[ -z "$(sudo dpkg -l | grep openssh-server)" ]]; then

        run_apt_get_update

        logger 'Configuring SSH'
        run_apt_get_install  'openssh-client' 'openssh-server' 'openssh-sftp-server' 'ssh'

        logger "Restarting the SSH service..."
        service ssh stop | tee -a "${TMP_LOG_FILE}"
        service ssh start | tee -a "${TMP_LOG_FILE}"

    else
        logger "SSH server is already installed!"
    fi

    print_line

}


#######################################
# Starts the system setup
# Globals:
#   DIALOG_OPT_UPDATE
#   DIALOG_OPT_PROXY_SYSTEM
#   DIALOG_OPT_PROXY_APT
#   MESSAGE_UPDATING_CONFIG
#   MESSAGE_CONF_PROXY_APT
#   MESSAGE_OPEN_LOG_FILE
#   TMP_LOG_FILE
# Arguments:
#   None
# Returns:
#   None
#######################################
function start_set_up(){

    load_properties_file

    options=$(zenity  --list  \
            --text "${DIALOG_TITLE}" \
            --checklist  \
            --column "[X]" \
            --column "${DIALOG_OPTIONS}" \
            TRUE "${DIALOG_OPT_PROXY_SYSTEM}" \
            TRUE "${DIALOG_OPT_PROXY_APT}" \
            TRUE "${DIALOG_OPT_BROWSER_PROXY}" \
            FALSE "${DIALOG_OPT_UPDATE}" \
            --height 300)

    options="$(tr '|' ' ' <<< ${options})"

    if [[ -z "${options}" ]]; then
        logger "No option checked! Exiting!"
    fi

   for opt in $options; do
       case ${opt} in
           "${DIALOG_OPT_PROXY_SYSTEM}")
                set_proxy_to_env
           ;;
           "${DIALOG_OPT_PROXY_APT}")
                logger "${MESSAGE_CONF_PROXY_APT}"
                set_proxy_to_apt
           ;;
           "${DIALOG_OPT_UPDATE}")
                update_system --run-dpkg #--run-update
           ;;
           "${DIALOG_OPT_BROWSER_PROXY}")
                set_proxy_to_firefox
                set_proxy_to_chromium
                configure_firefox_profile
           ;;
           *)
                logger "Option ${opt} not found! exiting."
           ;;
       esac
   done

}


#######################################
# Test if user is root, if so
# start to work, otherwise, creates a
# copy of itself and try to run it as
# root.
# Globals:
#   PESCAR_DEFAULT_PASSWORD
#   THIS_SCRIPT_PATH
#   IT_HAS_RUN
#   USER
# Arguments:
#   None
# Returns:
#   None
#######################################
function main(){ 
    local time_to_wait=30

    if [[ "$(id -u)" == "0" ]]; then
        # If we are here, the script is being run as root.
        touch "${TMP_LOG_FILE}"
        chmod 777 "${TMP_LOG_FILE}"

        start_set_up

        touch "${IT_HAS_RUN}"
        chown pescar.pescar "${IT_HAS_RUN}"

        logger "Exiting in ${time_to_wait} seconds."
        sleep ${time_to_wait}
    else
        # Try to use a default password to run this script
        sudo -S "${THIS_SCRIPT_PATH}" <<< "${PESCAR_DEFAULT_PASSWORD}"

        # Well, it didn't work, so let's ask user to enter the password.
        if [[ ! -f "${IT_HAS_RUN}" ]]; then
            clear
            print_header "${MESSAGE_ENTER_PASSWORD} ${USER}"
        fi

        [[ -f "${IT_HAS_RUN}" ]] && rm -f "${IT_HAS_RUN}"
    fi

}


# Start it!
main
