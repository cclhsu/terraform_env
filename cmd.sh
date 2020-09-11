#!/usr/bin/env bash
#******************************************************************************

# Copyright 2015 Clark Hsu
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#******************************************************************************
# How To
# https://docs.openstack.org/image-guide/obtain-images.html
# https://cloudinit.readthedocs.io/en/latest/topics/examples.html

# ssh-keygen -R 10.17.2.0 -f /home/cclhsu/.ssh/known_hosts
# ssh root@10.17.2.0

#******************************************************************************
# Mark Off this section if use as lib

PROGRAM_NAME=$(basename "${0}")
AUTHOR=clark_hsu
VERSION=0.0.1

#******************************************************************************
echo -e "\n================================================================================\n"
#echo "Begin: $(basename "${0}")"
#set -e # Exit on error On
#set -x # Trace On
#******************************************************************************
# Load Configuration

echo -e "\n>> Load Configuration...\n"
TOP_DIR=$(cd "$(dirname "${0}")" && pwd)
# shellcheck source=/dev/null
source "${HOME}/.mysecrets"
# shellcheck source=/dev/null
source "${HOME}/.myconfigs"
# shellcheck source=/dev/null
source "${HOME}/.mylib"
# TOP_DIR=${CLOUD_MOUNT_PATH}
# TOP_DIR=${CLOUD_REPLICA_PATH}
# TOP_DIR=${DOCUMENTS_PATH}
# source ${TOP_DIR}/_common_lib.sh
# source "${TOP_DIR}/setup.conf"
echo "${PASSWORD}" | sudo -S echo ""
if [ "${OPTION}" == "" ]; then
    OPTION="${1}"
fi

#******************************************************************************
# Conditions Check and Init

# check_if_root_user
# detect_package_system

#******************************************************************************
# Usage & Version

usage() {
    cat <<EOF

Usage: ${0} -a <ACTION> [-o <OPTION>]

This script is to <DO ACTION>.

OPTIONS:
    -h | --help             Usage
    -v | --version          Version
    -a | --action           Action [a|b|c]

EOF
    exit 1
}

version() {
    cat <<EOF

Program: ${PROGRAM_NAME}
Author: ${AUTHOR}
Version: ${VERSION}

EOF
    exit 1
}

#******************************************************************************
# Command Line Parameters

while [[ "$#" -gt 0 ]]; do
    OPTION="${1}"
    case ${OPTION} in
        -h | --help)
            usage
            ;;
        -v | --version)
            version
            ;;
        -a | --action)
            ACTION="${2}"
            shift
            ;;
        -p | --platform)
            PLATFORM="${2}"
            shift
            ;;
        -o | --os)
            OS="${2}"
            shift
            ;;
        *)
            # Others / Unknown Option
            #usage
            ;;
    esac
    shift # past argument or value
done

if [ "${ACTION}" != "" ]; then
    case ${ACTION} in
        a | b | c) ;;
        create_project_skeleton | clean_project) ;;
        install | uninstall) ;;
        deploy_infrastructure | undeploy_infrastructure) ;;
        deploy | undeploy) ;;
        clean_project) ;;

        *)
            usage
            ;;
    esac
#else
#    usage
fi

#******************************************************************************
# Functions

# function function_01() {
#     if [ "$#" != "1" ]; then
#         log_e "Usage: ${FUNCNAME[0]} <ARGS>"
#     else
#         log_m "${FUNCNAME[0]} ${*}"
#     fi
# }

function create_project_skeleton() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ROLE>"
    else
        log_m "${FUNCNAME[0]} ${*}"

        mkdir -p "${TOP_DIR}"
        cd "${TOP_DIR}" || exit 1

        # rm -rf ${TOP_DIR}/{providers,inventories,state}
        mkdir -p ${TOP_DIR}/{providers,inventories,state}/{aws,azure,bare-metal,gcp,libvirt,openstack,vmware,vsphere}/{centos,debian,macos,opensuse,opensuseleap,opensusetumbleweed,sles,ubuntu}/cloud-init scripts
        touch ${TOP_DIR}{providers/{aws,azure,bare-metal,gcp,libvirt,openstack,vmware,vsphere}/{centos,debian,macos,opensuse,opensuseleap,opensusetumbleweed,sles,ubuntu}/empty.tf
        # mkdir -p ${TOP_DIR}/{providers,inventories,state}/{libvirt,openstack}/{centos,macos,opensuseleap,sles,ubuntu}
        # mkdir -p ${TOP_DIR}/{inventories}/{libvirt,openstack}/{centos,macos,opensuseleap,sles,ubuntu}/{<service>,server,client,helloworld}/{bin,rootfs}
        # mkdir -p ${TOP_DIR}/{inventories}/{libvirt,openstack}/{centos,macos,opensuseleap,sles,ubuntu}/{<service>,server,client,helloworld}/rootfs/{etc,usr,var}
        # mkdir -p ${TOP_DIR}/{inventories}/{libvirt,openstack}/{centos,macos,opensuseleap,sles,ubuntu}/{<service>,server,client,helloworld}/bin/{daemon,container}
    fi
}

function install_terraform() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        log_m "${FUNCNAME[0]}" # ${*}

        cd "${TOP_DIR}" || exit 1

        # https://github.com/hashicorp/terraform/releases
        # https://releases.hashicorp.com/terraform/
        local VERSION=0.12.29 # 0.13.0 | 0.12.29
        local OS=linux        # darwin | linux
        local ARCH=amd64      # amd64

        mkdir -p "${TOP_DIR}/bin"
        if [ ! -e "${TOP_DIR}/bin/terraform_${VERSION}_${OS}_${ARCH}.zip" ]; then
            # curl -L https://github.com/hashicorp/terraform/archive/v${VERSION}.tar.gz -o ${TOP_DIR}/bin/terraform-${VERSION}.tar.gz
            curl -L https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_${OS}_${ARCH}.zip -o ${TOP_DIR}/bin/terraform_${VERSION}_${OS}_${ARCH}.zip
        fi

        cd "${TOP_DIR}/bin" || exit 1
        unzip ${TOP_DIR}/bin/terraform_${VERSION}_${OS}_${ARCH}.zip
        chmod +x ${TOP_DIR}/bin/terraform
        sudo mv ${TOP_DIR}/bin/terraform /usr/bin
        # sudo mv ${TOP_DIR}/bin/terraform /usr/loal/bin
        ls "/usr/bin/terraform"
        terraform --version
    fi
}

function uninstall_terraform() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        log_m "${FUNCNAME[0]}" # ${*}
        sudo rm -f /usr/bin/terraform
        ls "/usr/bin/terraform"

        # https://github.com/hashicorp/terraform/releases
        # https://releases.hashicorp.com/terraform/
        local VERSION=0.12.29 # 0.13.0 | 0.12.29
        local OS=linux        # darwin | linux
        local ARCH=amd64      # amd64

        rm ${TOP_DIR}/bin/terraform_${VERSION}_${OS}_${ARCH}.zip
    fi
}

function install_terraform_provider_libvirt() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <PLATFORM> <OS> <ARCH>"
    else
        log_m "${FUNCNAME[0]}" # ${*}

        if [ "${PLATFORM}" == "libvirt" ]; then

            cd "${TOP_DIR}" || exit 1

            # https://github.com/dmacvicar/terraform-provider-libvirt/releases
            local VERSION=0.6.2
            local TAG=+git.1585292411.8cbe9ad0
            local OS=openSUSE_Leap_15.1
            local ARCH=x86_64

            mkdir -p "${TOP_DIR}/bin"
            # curl -L https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.2/terraform-provider-libvirt-0.6.2+git.1585292411.8cbe9ad0.openSUSE_Leap_15.2.x86_64.tar.gz
            curl -L https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v${VERSION}/terraform-provider-libvirt-${VERSION}${TAG}.${OS}.${ARCH}.tar.gz -o ${TOP_DIR}/bin/terraform-provider-libvirt-${VERSION}.${OS}.${ARCH}.tar.gz

            cd "${TOP_DIR}/bin" || exit 1
            tar -xvf ${TOP_DIR}/bin/terraform-provider-libvirt-${VERSION}.${OS}.${ARCH}.tar.gz
            rm ${TOP_DIR}/bin/terraform-provider-libvirt-${VERSION}.${OS}.${ARCH}.tar.gz
            mkdir -p "${HOME}/.terraform.d/plugins"
            mv "${TOP_DIR}/bin/terraform-provider-libvirt" "${HOME}/.terraform.d/plugins/"
            ls "${HOME}/.terraform.d/plugins"
            ${HOME}/.terraform.d/plugins/terraform-provider-libvirt --version

        fi
    fi
}

function uninstall_terraform_provider_libvirt() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <PLATFORM>"
    else
        log_m "${FUNCNAME[0]}" # ${*}
        rm -rf "${HOME}/.terraform.d/plugins/terraform-provider-libvirt"
        rm -rf ${TOP_DIR}/bin/*
        ls "${HOME}/.terraform.d/plugins"
    fi
}

function install_terraform_provider_susepubliccloud() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <PLATFORM> <OS>"
    else
        log_m "${FUNCNAME[0]}" # ${*}

        cd "${TOP_DIR}" || exit 1

        if [ "${PLATFORM}" == "aws" ] && [ "${OS}" == "sles" ]; then
            sudo zypper addrepo --refresh http://download.suse.de/ibs/SUSE:/SLE-15-SP2:/Update:/Products:/CASP40/standard/SUSE:SLE-15-SP2:Update:Products:CASP40.repo
            sudo zypper addrepo --refresh http://updates.suse.de/SUSE/Updates/SUSE-CAASP/4.0/x86_64/update/SUSE:Updates:SUSE-CAASP:4.0:x86_64.repo
            # sudo zypper addrepo --refresh http://download.suse.de/ibs/Devel:/CaaSP:/4.0/SLE_15_SP2/Devel:CaaSP:4.0.repo

            sudo zypper --gpg-auto-import-keys install -y terraform-provider-susepubliccloud
            # TERRAFORM_VERSION=0.12.19 # 0.12.19 | 0.12.25
            # sudo zypper --gpg-auto-import-keys install -y terraform=${TERRAFORM_VERSION} terraform-provider-local terraform-provider-null terraform-provider-template
            # sudo zypper --gpg-auto-import-keys install -y terraform=${TERRAFORM_VERSION} terraform-provider-aws terraform-provider-susepubliccloud
            # sudo zypper --gpg-auto-import-keys install -y terraform=${TERRAFORM_VERSION} terraform-provider-aws terraform-provider-local terraform-provider-null terraform-provider-openstack terraform-provider-susepubliccloud terraform-provider-template terraform-provider-vsphere
        fi

    fi
}

function uninstall_terraform_provider_susepubliccloud() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <PLATFORM> <OS>"
    else
        log_m "${FUNCNAME[0]}" # ${*}

        cd "${TOP_DIR}" || exit 1

        if [ "${PLATFORM}" == "aws" ] && [ "${OS}" == "sles" ]; then
            # TERRAFORM_VERSION=0.12.19 # 0.12.19 | 0.12.25
            sudo zypper remove -y terraform terraform-provider-aws terraform-provider-local terraform-provider-null terraform-provider-openstack terraform-provider-susepubliccloud terraform-provider-template terraform-provider-vsphere
            sudo zypper removerepo Devel_CaaSP_4.0
            sudo zypper removerepo SUSE_SLE-15-SP2_Update_Products_CASP40
            sudo zypper removerepo SUSE_Updates_SUSE-CAASP_4.0_x86_64
        fi
    fi
}

# function install_terraform_provider_vix() {
#     if [ "$#" != "0" ]; then
#         log_e "Usage: ${FUNCNAME[0]} <ARGS>"
#     else
#         log_m "${FUNCNAME[0]}" # ${*}

#         # https://github.com/hooklift/terraform-provider-vix/releases
#         :
#     fi
# }

# function uninstall_terraform_provider_vix() {
#     if [ "$#" != "0" ]; then
#         log_e "Usage: ${FUNCNAME[0]} <ARGS>"
#     else
#         log_m "${FUNCNAME[0]}" # ${*}
#         rm -rf "${HOME}/.terraform.d/plugins/terraform-provider-vix"
#     fi
# }

# function install_terraform_provider_esxi() {
#     if [ "$#" != "0" ]; then
#         log_e "Usage: ${FUNCNAME[0]} <ARGS>"
#     else
#         log_m "${FUNCNAME[0]}" # ${*}

#         # https://github.com/josenk/terraform-provider-esxi/releases
#         VERSION=1.6.2

#         mkdir -p "${TOP_DIR}/bin"
#         curl -L https://github.com/josenk/terraform-provider-esxi/releases/download/v${VERSION}/terraform-provider-esxi_v${VERSION} -o ${TOP_DIR}/bin/terraform-provider-esxi

#         cd "${TOP_DIR}/bin" || exit 1
#         # tar -zxvf ${TOP_DIR}/bin/terraform-provider-esxi-${VERSION}.tar.gz
#         # rm ${TOP_DIR}/bin/terraform-provider-esxi-${VERSION}.tar.gz
#         mkdir -p "${HOME}/.terraform.d/plugins"
#         mv "${TOP_DIR}/bin/terraform-provider-esxi" "${HOME}/.terraform.d/plugins/"
#         ls "${HOME}/.terraform.d/plugins"
#         # ${HOME}/.terraform.d/plugins/terraform-provider-esxi --version
#     fi
# }

# function uninstall_terraform_provider_esxi() {
#     if [ "$#" != "0" ]; then
#         log_e "Usage: ${FUNCNAME[0]} <ARGS>"
#     else
#         log_m "${FUNCNAME[0]}" # ${*}
#         rm -rf "${HOME}/.terraform.d/plugins/terraform-provider-esxi"
#         ls "${HOME}/.terraform.d/plugins"
#     fi
# }

function start_libvirtd() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        if [ ! -e "/var/run/libvirt/libvirt-sock" ]; then
            echo -e "\n>> Start Libvirtd...\n"
            sudo systemctl start libvirtd
            # sudo systemctl enable libvirtd
            sudo systemctl status libvirtd
        fi
    fi
}

function stop_libvirtd() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        if [ -e "/var/run/libvirt/libvirt-sock" ]; then
            echo -e "\n>> Stop Libvirtd...\n"
            # https://doc.opensuse.org/documentation/leap/archive/42.1/virtualization/html/book.virt/cha.libvirt.networks.html
            virsh net-list --all
            NETWORK=${OS}-network # centos debian opensuse sles ubuntu
            virsh net-destroy ${NETWORK}
            virsh net-undefine ${NETWORK}
            sudo systemctl stop libvirtd
            # sudo systemctl disable libvirtd
            sudo systemctl status libvirtd
        fi
    fi
}

function source_rc() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <PLATFORM>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        case ${1} in
            aws | azure | gcp | openstack | vmware | vsphere)
                echo -e "\n>> Source ${1} RC...\n"
                check_file_exist "${TOP_DIR}/container-openrc-${1}.sh"
                if [[ $? -ne 0 ]]; then
                    echo -e "\nPlease download/setup container-openrc-${1}.sh"
                    exit 1
                fi
                # shellcheck source=/dev/null
                source "${TOP_DIR}/container-openrc-${1}.sh"
                ;;
            libvirt) ;;

            *) ;;
        esac
    fi
}

function dry_run() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_DIR>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        echo -e "\n>> Deploy Nodes...\n"

        rm -rf "${HOME}/.ssh/known_hosts"
        cd "${1}" || exit 1
        if [ ! -e "terraform.tfvars" ]; then
            cp terraform.tfvars.example terraform.tfvars
        fi
        /usr/bin/terraform init
        terraform validate .
        /usr/bin/terraform plan
        check_run_state $?
    fi
}

function deploy() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_DIR>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        echo -e "\n>> Deploy Nodes...\n"

        if [ ! -e "/var/lib/libvirt/images" ]; then
            sudo mkdir -p "/var/lib/libvirt/images"
        fi

        rm -rf "${HOME}/.ssh/known_hosts"
        cd "${1}" || exit 1
        /usr/bin/terraform init
        # /usr/bin/terraform plan
        /usr/bin/terraform apply -auto-approve
        check_run_state $?
        if [ "${PLATFORM}" == "openstack" ]; then
            sudo ls /tmp/terraform-provider-libvirt-pool-*/
        fi
    fi
}

function undeploy() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_DIR> [<TFSTATE_DIR>] [<PROJECT_NAME>] [<VM_IMAGE_DIR>]"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        echo -e "\n>> Undeploy Nodes...\n"

        cd "${1}" || exit 1
        /usr/bin/terraform destroy -auto-approve -parallelism=1
        check_run_state $?
        if [ "${PLATFORM}" == "openstack" ]; then
            # sudo rm -rf /tmp/terraform-provider-libvirt-pool-*/
            sudo ls /tmp/terraform-provider-libvirt-pool-*/
        fi
    fi
}

function show_terraform_state() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_DIR> [<TFSTATE_DIR>]"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        echo -e "\n>> Show Terraform state in ${1}...\n"

        cd "${1}" || exit 1
        /usr/bin/terraform output
    fi
}

function clean_project() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        cd "${TOP_DIR}" || exit 1
        find . -name "\.terraform*" -exec rm -rf {} \;
        find . -name "terraform.tfstate*" -exec rm -rf {} \;

        sudo rm -rf /tmp/terraform-provider-libvirt-pool-*
        sudo find /etc/libvirt -name centos* -exec rm -rf {} \;
        sudo find /etc/libvirt -name debian* -exec rm -rf {} \;
        sudo find /etc/libvirt -name opensuse* -exec rm -rf {} \;
        sudo find /etc/libvirt -name ubuntu* -exec rm -rf {} \;
        sudo find /etc/libvirt -name leap15* -exec rm -rf {} \;
        sudo find /etc/libvirt -name sles* -exec rm -rf {} \;
        # sudo rm -rf /etc/libvirt/qemu/{centos,debian,opensuse,sles,ubuntu,leap15}-*.xml
        sudo rm -rf /etc/libvirt/qemu/networks/{mos,centos,debian,opensuse,sles,ubuntu,leap15}.xml
        sudo rm -rf /etc/libvirt/qemu/networks/{mos,centos,debian,opensuse,sles,ubuntu,leap15}-network.xml
        sudo rm -rf /etc/libvirt/qemu/networks/autostart/{mos,centos,debian,opensuse,sles,ubuntu,leap15}.xml
        sudo rm -rf /etc/libvirt/qemu/networks/autostart/{mos,centos,debian,opensuse,sles,ubuntu,leap15}-network.xml
        sudo rm -rf /etc/libvirt/storage/{centos,debian,opensuse,sles,ubuntu,leap15}.xml
        sudo rm -rf /etc/libvirt/storage/autostart/{centos,debian,opensuse,sles,ubuntu,leap15}.xml
        STACK_NAME=my-cluster
        sudo rm -rf ${HOME}/.config/libvirt/qemu/networks/${STACK_NAME}-network.xml

        sudo rm -rf ${HOME}/Documents/myImages/libvirt/images
        sudo mkdir -p ${HOME}/Documents/myImages/libvirt/images
        sudo ls -al ${HOME}/Documents/myImages/libvirt/images
        sudo rm -rf /var/lib/libvirt/dnsmasq/{mos,centos,debian,opensuse,sles,ubuntu,leap15}-network.*
        sudo rm -rf /var/lib/libvirt/qem/domain-*
        # VM_IMAGE_DIR=/var/lib/libvirt/images
        # ALT_VM_IMAGE_DIR=${HOME}/Documents/myImages/libvirt/images
        # sudo rm -rf ${VM_IMAGE_DIR}
        # sudo mkdir -p "${ALT_VM_IMAGE_DIR}"
        # sudo ln -s "${ALT_VM_IMAGE_DIR}" "${VM_IMAGE_DIR}"
    fi
}

function clean_libvirt() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        cd "${TOP_DIR}" || exit 1

        sudo rm -rf /tmp/terraform-provider-libvirt-pool-*
        sudo find /etc/libvirt -name centos* -exec rm -rf {} \;
        sudo find /etc/libvirt -name debian* -exec rm -rf {} \;
        sudo find /etc/libvirt -name opensuse* -exec rm -rf {} \;
        sudo find /etc/libvirt -name ubuntu* -exec rm -rf {} \;
        sudo find /etc/libvirt -name leap15* -exec rm -rf {} \;
        sudo find /etc/libvirt -name sles* -exec rm -rf {} \;
        # sudo rm -rf /etc/libvirt/qemu/{centos,debian,opensuse,sles,ubuntu,leap15}-*.xml
        sudo rm -rf /etc/libvirt/qemu/networks/{mos,centos,debian,opensuse,sles,ubuntu,leap15}.xml
        sudo rm -rf /etc/libvirt/qemu/networks/{mos,centos,debian,opensuse,sles,ubuntu,leap15}-network.xml
        sudo rm -rf /etc/libvirt/qemu/networks/autostart/{mos,centos,debian,opensuse,sles,ubuntu,leap15}.xml
        sudo rm -rf /etc/libvirt/qemu/networks/autostart/{mos,centos,debian,opensuse,sles,ubuntu,leap15}-network.xml
        sudo rm -rf /etc/libvirt/storage/{centos,debian,opensuse,sles,ubuntu,leap15}.xml
        sudo rm -rf /etc/libvirt/storage/autostart/{centos,debian,opensuse,sles,ubuntu,leap15}.xml
        STACK_NAME=my-cluster
        sudo rm -rf ${HOME}/.config/libvirt/qemu/networks/${STACK_NAME}-network.xml

        sudo rm -rf ${HOME}/Documents/myImages/libvirt/images
        sudo mkdir -p ${HOME}/Documents/myImages/libvirt/images
        sudo ls -al ${HOME}/Documents/myImages/libvirt/images
        sudo rm -rf /var/lib/libvirt/dnsmasq/{mos,centos,debian,opensuse,sles,ubuntu,leap15}-network.*
        sudo rm -rf /var/lib/libvirt/qem/domain-*
        # VM_IMAGE_DIR=/var/lib/libvirt/images
        # ALT_VM_IMAGE_DIR=${HOME}/Documents/myImages/libvirt/images
        # sudo rm -rf ${VM_IMAGE_DIR}
        # sudo mkdir -p "${ALT_VM_IMAGE_DIR}"
        # sudo ln -s "${ALT_VM_IMAGE_DIR}" "${VM_IMAGE_DIR}"
    fi
}

function list_local_images() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"

        # find / -name *.iso 2>/dev/null
        # find / -name *.qcow2 2>/dev/null
        # find / -name *.img 2>/dev/null
        # find / -name *.vmdk 2>/dev/null

        echo -e "\n>> kvm/centos...\n"
        ls -al ${HOME}/Documents/myImages/kvm/centos/ || true
        echo -e "\n>> kvm/debian...\n"
        ls -al ${HOME}/Documents/myImages/kvm/debian/ || true
        echo -e "\n>> kvm/openSUSE...\n"
        ls -al ${HOME}/Documents/myImages/kvm/opensuse/ || true
        echo -e "\n>> kvm/SLES...\n"
        ls -al ${HOME}/Documents/myImages/kvm/sles/ || true
        echo -e "\n>> kvm/ubuntu...\n"
        ls -al ${HOME}/Documents/myImages/kvm/ubuntu/ || true
        echo -e "\n>> /var/lib/libvirt/images...\n"
        sudo ls -al /var/lib/libvirt/images || true
        echo -e "\n>> ${HOME}/Documents/myImages/libvirt/images...\n"
        sudo ls -al ${HOME}/Documents/myImages/libvirt/images || true

        echo -e "\n>> /etc/libvirt...\n"
        sudo ls -al /etc/libvirt/qemu || true
        sudo ls -al /etc/libvirt/qemu/networks || true
        sudo ls -al /etc/libvirt/qemu/networks/autostart || true
        sudo ls -al /etc/libvirt/storage || true
        sudo ls -al /etc/libvirt/storage/autostart || true
        # sudo rm -rf /var/lib/libvirt/dnsmasq/*-network.pi*
        # sudo ls -al /var/lib/libvirt/dnsmasq || true

        echo -e "\n>> /tmp/terraform-provider-libvirt-pool-*...\n"
        sudo ls -l /tmp/terraform-provider-libvirt-pool-* || true

        # ls -al ${HOME}/.cache/libvirt/

    fi
}

function ssh_to() {
    if [ "$#" != "2" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_TOP_DIR> <INSTANCES_TYPE>"
    else
        log_m "${FUNCNAME[0]} ${*}"

        clear
        cd "${1}" || exit 1
        SSH_USER=$(terraform output username)
        if [ "${SSH_USER}" == "" ]; then
            select_x_from_array "centos debian mos opensuse sles ubuntu root ec2-user" "SSH_USER" SSH_USER
        fi
        # IP_INSTANCES=$(terraform output ${2} | sed '1,1d' | sed '$ d' | sed 's/^[ \t]*//' | tr -d '\n' | sed 's/,/ /g' | sed 's/"//g')
        IP_INSTANCES=$(terraform output ${2} | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
        select_x_from_array "${IP_INSTANCES}" "IP" IP
        echo "${SSH_USER}" "${IP}"
        if [ ${PRINT_CLOUD_INIT_LOG} == true ]; then
            ssh_cmd "${SSH_USER}" "${IP}" "sudo cat /var/log/cloud-init.log"
            # util.py[DEBUG]: The system is finally up, after 8.70 seconds
            # main.py[DEBUG]: Ran 10 modules with 0 failures
            # util.py[DEBUG]: Creating symbolic link from '/run/cloud-init/result.json' => '../../var/lib/cloud/data/result.json'
            # util.py[DEBUG]: Reading from /proc/uptime (quiet=False)
            # util.py[DEBUG]: Read 10 bytes from /proc/uptime
            # util.py[DEBUG]: cloud-init mode 'modules' took 0.117 seconds (0.11)
            # handlers.py[DEBUG]: finish: modules-final: SUCCESS: running modules for final
        fi
        ssh_cmd "${SSH_USER}" "${IP}"
    fi
}

#******************************************************************************
# Selection Parameters

if [ "${ACTION}" == "" ]; then
    MAIN_OPTIONS="\
        create_project_skeleton clean_project \
        install uninstall \
        start_libvirtd stop_libvirtd \
        dry_run deploy undeploy status \
        clean_project clean_libvirt \
        list_local_images output \
        ssh_to ssh_to_lb ssh_to_etcd ssh_to_storage ssh_to_master ssh_to_worker"

    select_x_from_array "${MAIN_OPTIONS}" "Action" ACTION # "a"
fi

# if [ "${XXX}" == "" ]; then
#     # select_x_from_array "a b c" "XXX" XXX # "a"
#     read_and_confirm "XXX MSG" XXX #"XXX set value"
# fi

if [ "${PLATFORM}" == "" ]; then
    # select_x_from_array "aws azure bare-metal gcp libvirt openstack vmware vsphere" "PLATFORM" PLATFORM # "openstack"
    read_and_confirm "PLATFORM MSG" PLATFORM "libvirt"
fi
if [ "${OS}" == "" ]; then
    # select_x_from_array "centos debian macos opensuse opensuseleap opensusetumbleweed sles ubuntu" "OS" OS # "sles"
    read_and_confirm "OS MSG" OS "opensuse" # "sles" | "sandbox"
fi
if [ "${ARCH}" == "" ]; then
    # select_x_from_array "amd64 x86_64" "ARCH" ARCH # "amd64"
    read_and_confirm "ARCH MSG" ARCH "amd64"
fi
# echo "${PLATFORM}/${OS}/${ARCH}"
DEPLOYMENT_TOP_DIR=${TOP_DIR}/providers/${PLATFORM}/${OS}
PRINT_CLOUD_INIT_LOG=false

#******************************************************************************
# Main Program

sync_time
source_rc "${PLATFORM}"
rm -rf "${HOME}/.ssh/known_hosts"
# https://www.ssh.com/ssh/agent
# ssh-agent bash
ssh-add "${HOME}/.ssh/id_rsa"

case ${ACTION} in
    create_project_skeleton)
        create_project_skeleton
        ;;

    # clean_project)
    #     clean_project
    #     ;;

    install)
        install_terraform
        install_terraform_provider_libvirt         # ${PLATFORM} ${OS} ${ARCH}
        install_terraform_provider_susepubliccloud # ${PLATFORM} ${OS}
        # install_terraform_provider_vix
        # install_terraform_provider_esxi
        ;;
    uninstall)
        uninstall_terraform
        uninstall_terraform_provider_libvirt         # ${PLATFORM} ${OS} ${ARCH}
        uninstall_terraform_provider_susepubliccloud # ${PLATFORM} ${OS}
        # uninstall_terraform_provider_vix
        # uninstall_terraform_provider_esxi
        ;;

    start_libvirtd)
        start_libvirtd
        ;;
    stop_libvirtd)
        stop_libvirtd
        ;;

    dry_run)
        if [ "${PLATFORM}" == "libvirt" ]; then
            start_libvirtd
        fi
        dry_run "${DEPLOYMENT_TOP_DIR}"
        ;;
    deploy)
        if [ "${PLATFORM}" == "libvirt" ]; then
            start_libvirtd
        fi
        deploy "${DEPLOYMENT_TOP_DIR}"
        ;;
    undeploy)
        undeploy "${DEPLOYMENT_TOP_DIR}"
        ;;

    status)
        show_terraform_state "${DEPLOYMENT_TOP_DIR}"
        ;;

    clean_project)
        if [ "${PLATFORM}" == "libvirt" ]; then
            stop_libvirtd
        fi
        clean_project
        ;;
    clean_libvirt)
        if [ "${PLATFORM}" == "libvirt" ]; then
            stop_libvirtd
        fi
        clean_libvirt
        ;;

    list_local_images)
        list_local_images
        ;;

    output)
        cd "${DEPLOYMENT_TOP_DIR}" || exit 1
        terraform output
        ;;
    ssh_to)
        ssh_to "${DEPLOYMENT_TOP_DIR}" "ip_instances"
        ;;
    ssh_to_lb)
        ssh_to "${DEPLOYMENT_TOP_DIR}" "ip_load_balancer"
        ;;
    ssh_to_etcd)
        ssh_to "${DEPLOYMENT_TOP_DIR}" "ip_etcds"
        # ssh_to "${DEPLOYMENT_TOP_DIR}" "etcds_public_ip"
        ;;
    ssh_to_storage)
        ssh_to "${DEPLOYMENT_TOP_DIR}" "ip_storages"
        # ssh_to "${DEPLOYMENT_TOP_DIR}" "storages_public_ip"
        ;;
    ssh_to_master)
        ssh_to "${DEPLOYMENT_TOP_DIR}" "ip_masters"
        # ssh_to "${DEPLOYMENT_TOP_DIR}" "masters_public_ip"
        ;;
    ssh_to_worker)
        ssh_to "${DEPLOYMENT_TOP_DIR}" "ip_workers"
        # ssh_to "${DEPLOYMENT_TOP_DIR}" "workers_public_ip"
        ;;

    *)
        # Others / Unknown Option
        usage
        ;;
esac

# find ${TOP_DIR} -type d -name bin -exec sh -c "rm -rf {}" {} \;

#******************************************************************************
#set +e # Exit on error Off
#set +x # Trace Off
#echo "End: $(basename "${0}")"
echo -e "\n================================================================================\n"
exit 0
#******************************************************************************
