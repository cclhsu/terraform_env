#!/usr/bin/env bash
#******************************************************************************
# Copyright 2020 Clark Hsu
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

echo -e "\n>>> Load Configuration...\n"
TOP_DIR=$(cd "$(dirname "${0}")" && pwd)
# shellcheck source=/dev/null
source "${HOME}/.mysecrets"
# shellcheck source=/dev/null
source "${HOME}/.myconfigs"
# shellcheck source=/dev/null
source "${HOME}/.mylib"
# shellcheck source=/dev/null
source "${HOME}/.myprojects"
# TOP_DIR=${CLOUD_MOUNT_PATH}
# TOP_DIR=${CLOUD_REPLICA_PATH}
# TOP_DIR=${DOCUMENTS_PATH}
# source "${TOP_DIR:?}/_common_lib.sh"
# source "${TOP_DIR:?}/setup.conf"
echo "${PASSWORD}" | sudo -S echo ""
if [ "${OPTION}" == "" ]; then
    OPTION="${1}"
fi

#******************************************************************************
# Conditions Check and Init

# check_if_root_user
detect_package_system
set_alias_by_distribution  # ${DISTRO}
PROJECT_TYPE=terraform_app # ansible_app bash_app bash_deployment_app bash_install_app bash_remote_deployment_app docker_app helm_app helm3_app minifest_app deployment_app terraform_app

#******************************************************************************
# Usage & Version

usage() {
    cat <<EOF

Usage: ${0} -a <ACTION> [-o <OPTION>]

This script is to <DO ACTION>.

OPTIONS:
    -h | --help             Usage
    -v | --version          Version
    -a | --action           Action [create_project_skeleton | clean_project |
                                    start_runtime | stop_runtime |
                                    deploy_infrastructure | undeploy_infrastructure | install_infrastructure_requirements | uninstall_infrastructure_requirements |
                                    install | update | upgrade | dist-upgrade | uninstall |
                                    configure | remove_configurations |
                                    enable | start | stop | disable |
                                    deploy | undeploy | upgrade | backup | restore |
                                    show_infrastructure_status | show_k8s_status | show_app_status |
                                    access_service | access_service_by_proxy | ssh_to_node |
                                    status | get_version | lint | build]

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
        -hd | --distro)
            DISTRO="${2}"
            shift
            ;;
        -o | --os)
            OS="${2}"
            shift
            ;;
        -a | --arch)
            ARCH="${2}"
            shift
            ;;
        -p | --platform)
            PLATFORM="${2}"
            shift
            ;;
        -pd | --platform_distro)
            PLATFORM_DISTRO="${2}"
            shift
            ;;
        -m | --install_method)
            INSTALL_METHOD="${2}"
            shift
            ;;
        -s | --source_directory)
            SRC_DIR="${2}"
            shift
            ;;
        -d | --destination_directory)
            DEST_DIR="${2}"
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
        start_runtime | stop_runtime) ;;
        deploy_infrastructure | undeploy_infrastructure | install_infrastructure_requirements | uninstall_infrastructure_requirements) ;;
        install | update | upgrade | dist-upgrade | uninstall) ;;
        configure | remove_configurations) ;;
        enable | start | stop | disable) ;;
        deploy | undeploy | upgrade | backup | restore) ;;
        show_infrastructure_status | show_k8s_status | show_app_status) ;;
        access_service | access_service_by_proxy | ssh_to_node) ;;
        status | get_version | lint | build) ;;

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
#         # cd "${TOP_DIR:?}" || exit 1
#     fi
# }

function start_runtime() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        if [ ! -e "/var/run/libvirt/libvirt-sock" ]; then
            echo -e "\n>>> Start Libvirtd...\n"
            sudo systemctl start libvirtd
            # sudo systemctl enable libvirtd
            sudo systemctl status libvirtd
        fi
    fi
}

function stop_runtime() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        if [ -e "/var/run/libvirt/libvirt-sock" ]; then
            echo -e "\n>>> Stop Libvirtd...\n"
            # https://doc.opensuse.org/documentation/leap/archive/42.1/virtualization/html/book.virt/cha.libvirt.networks.html
            sudo virsh net-list --all
            NETWORK=${PLATFORM_DISTRO}-network # centos debian opensuse-leap sles ubuntu
            sudo virsh net-destroy ${NETWORK}
            sudo virsh net-undefine ${NETWORK}
            sudo virsh net-destroy default
            sudo virsh net-undefine default
            sudo systemctl stop libvirtd
            # sudo systemctl disable libvirtd
            sudo systemctl status libvirtd
        fi
    fi
}

function deploy_infrastructure() {
    if [ "$#" != "3" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR> <PLATFORM> <PLATFORM_DISTRO>"
    else
        log_m "${FUNCNAME[0]} ${*}"
        cd "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" || exit 1

        echo -e "\n>>> Deploy Nodes...\n"

        if [ ! -e "/var/lib/libvirt/images" ]; then
            sudo mkdir -p "/var/lib/libvirt/images"
        fi

        rm -rf "${HOME}/.ssh/known_hosts"
        cd "${1}" || exit 1
        ${USER_BIN}/terraform init
        # ${USER_BIN}/terraform plan
        ${USER_BIN}/terraform apply -auto-approve
        check_run_state $?
        if [ "${PLATFORM}" == "openstack" ]; then
            sudo ls /tmp/terraform-provider-libvirt-pool-*/
        fi
    fi
}

function undeploy_infrastructure() {
    if [ "$#" != "3" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR> <PLATFORM> <PLATFORM_DISTRO>"
    else
        log_m "${FUNCNAME[0]} ${*}"
        cd "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" || exit 1

        echo -e "\n>>> Undeploy Nodes...\n"

        cd "${1}" || exit 1
        ${USER_BIN}/terraform destroy -auto-approve -parallelism=1
        check_run_state $?
        if [ "${PLATFORM}" == "openstack" ]; then
            # sudo rm -rf /tmp/terraform-provider-libvirt-pool-*/
            sudo ls /tmp/terraform-provider-libvirt-pool-*/
        fi
    fi
}

function install_infrastructure_requirements() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR> <SSH_USER> <IPS> <CONFIGURATION_MANAGEMENT_TOP_DIR> <REMOTE_CONFIGURATION_MANAGEMENT_TOP_DIR> <ROLE> <RUNTIME> <SCRIPT> <ARGS>"
    else
        log_m "${FUNCNAME[0]} ${*}"
        cd "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" || exit 1

    fi
}

function uninstall_infrastructure_requirements() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR> <SSH_USER> <IPS> <CONFIGURATION_MANAGEMENT_TOP_DIR> <REMOTE_CONFIGURATION_MANAGEMENT_TOP_DIR> <ROLE> <RUNTIME> <SCRIPT> <ARGS>"
    else
        log_m "${FUNCNAME[0]} ${*}"
        cd "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" || exit 1

    fi
}

function set_packages_by_distribution() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        if [ "${SRC_DIR}" == "" ]; then
            # SRC_DIR=${HOME}/Documents/myProject
            SRC_DIR=${HOME}/Documents/myProject/Template/helloworld_app
            # SRC_DIR=${HOME}/Documents/myProject/Template/helloworld_template
        fi

        INSTALL_METHOD=zip # bin tar bz2 xz rar zip script snap rpm go npm pip docker podman
        # https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases
        # https://repology.org/projects/?search=${GITHUB_PROJECT}
        PROJECT_BIN=terraform               #
        PROJECT_BIN_RUN_PARAMETERS=         #
        SYSTEMD_SERVICE_NAME=${PROJECT_BIN} #
        GITHUB_USER=hashicorp               #
        GITHUB_PROJECT=${PROJECT_BIN}       #
        # https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases
        # PACKAGE_VERSION=$(curl -s "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_PROJECT}/releases/latest" | jq --raw-output .tag_name)
        PACKAGE_VERSION=0.12.30 # 0.12.30 | 0.13.6 | 0.14.8 | 0.15.0-beta2
        echo ">>> Package: ${DISTRO}/${GITHUB_USER}/${GITHUB_PROJECT}/${PACKAGE_VERSION}/${PROJECT_BIN}-${OS}-${ARCH}"

        case ${DISTRO} in
            alpine)
                # https://pkgs.alpinelinux.org/packages
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME=
                PACKAGES_REPO_URL=
                PACKAGES="${PROJECT_BIN}"
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME=
                REQUIRED_PACKAGES_REPO_URL=
                REQUIRED_PACKAGES=
                PLUGIN_PACKAGES_KEY_URL=
                PLUGIN_PACKAGES_REPO_NAME=
                PLUGIN_PACKAGES_REPO_URL=
                PLUGIN_PACKAGES=
                ;;
            centos | fedora | rhel)
                # https://pkgs.org/
                # https://rpmfind.net/linux/RPM/index.html
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME=
                PACKAGES_REPO_URL=
                PACKAGES="${PROJECT_BIN}"
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME=
                REQUIRED_PACKAGES_REPO_URL=
                REQUIRED_PACKAGES=
                PLUGIN_PACKAGES_KEY_URL=
                PLUGIN_PACKAGES_REPO_NAME=
                PLUGIN_PACKAGES_REPO_URL=
                PLUGIN_PACKAGES=
                ;;
            cirros)
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME=
                PACKAGES_REPO_URL=
                PACKAGES="${PROJECT_BIN}"
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME=
                REQUIRED_PACKAGES_REPO_URL=
                REQUIRED_PACKAGES=
                PLUGIN_PACKAGES_KEY_URL=
                PLUGIN_PACKAGES_REPO_NAME=
                PLUGIN_PACKAGES_REPO_URL=
                PLUGIN_PACKAGES=
                ;;
            debian | raspios | ubuntu)
                # https://www.debian.org/distrib/packages
                # https://packages.ubuntu.com/
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME=
                PACKAGES_REPO_URL=
                PACKAGES="${PROJECT_BIN}"
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME=
                REQUIRED_PACKAGES_REPO_URL=
                REQUIRED_PACKAGES=
                PLUGIN_PACKAGES_KEY_URL=
                PLUGIN_PACKAGES_REPO_NAME=
                PLUGIN_PACKAGES_REPO_URL=
                PLUGIN_PACKAGES=
                ;;
            opensuse-leap | opensuse-tumbleweed | sles)
                # https://software.opensuse.org/find
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME="systemsmanagement_terraform"
                PACKAGES_REPO_URL="https://download.opensuse.org/repositories/systemsmanagement:terraform/openSUSE_Leap_15.2/systemsmanagement:terraform.repo"
                PACKAGES="${PROJECT_BIN}=${PACKAGE_VERSION}" # ${PROJECT_BIN} | ${PROJECT_BIN}=${PACKAGE_VERSION}
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME= # "systemsmanagement_terraform"
                REQUIRED_PACKAGES_REPO_URL=  # "https://download.opensuse.org/repositories/systemsmanagement:terraform/openSUSE_Leap_15.2/systemsmanagement:terraform.repo"
                REQUIRED_PACKAGES=           # "terraform-provider-aws terraform-provider-azurerm terraform-provider-gcp terraform-provider-libvirt terraform-provider-local terraform-provider-null terraform-provider-openstack terraform-provider-susepubliccloud terraform-provider-template terraform-provider-vsphere"
                PLUGIN_PACKAGES_KEY_URL=
                if [ "${INSTALL_METHOD}" != "rpm" ] && [ "${PLATFORM}" == "libvirt" ]; then
                    PLUGIN_PACKAGES_REPO_NAME=
                    PLUGIN_PACKAGES_REPO_URL=
                    PLUGIN_PACKAGES=
                else
                    PLUGIN_PACKAGES_REPO_NAME="systemsmanagement_terraform"
                    PLUGIN_PACKAGES_REPO_URL="https://download.opensuse.org/repositories/systemsmanagement:terraform/openSUSE_Leap_15.2/systemsmanagement:terraform.repo"
                    case ${PLATFORM} in
                        aws)
                            PLUGIN_PACKAGES="terraform-provider-aws terraform-provider-local terraform-provider-null terraform-provider-susepubliccloud terraform-provider-template"
                            ;;
                        azure)
                            PLUGIN_PACKAGES="terraform-provider-azurerm terraform-provider-local terraform-provider-null terraform-provider-susepubliccloud terraform-provider-template"
                            ;;
                        gcp)
                            PLUGIN_PACKAGES="terraform-provider-gcp terraform-provider-local terraform-provider-null terraform-provider-susepubliccloud terraform-provider-template"
                            ;;
                        libvirt)
                            PLUGIN_PACKAGES="terraform-provider-local terraform-provider-null terraform-provider-template"
                            ;;
                        openstack)
                            PLUGIN_PACKAGES="terraform-provider-local terraform-provider-null terraform-provider-openstack terraform-provider-template"
                            ;;
                        vmware | vsphere)
                            PLUGIN_PACKAGES="terraform-provider-local terraform-provider-null terraform-provider-template"
                            ;;
                        *) ;;
                    esac
                fi
                ;;
            macosx)
                # https://formulae.brew.sh/
                # https://formulae.brew.sh/cask/
                CASK=false
                [[ ${CASK} == true ]] && set_alias_by_distribution
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME=
                PACKAGES_REPO_URL=
                PACKAGES="${PROJECT_BIN}" # ${PROJECT_BIN} | ${PROJECT_BIN}@0.12
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME=
                REQUIRED_PACKAGES_REPO_URL=
                REQUIRED_PACKAGES=
                PLUGIN_PACKAGES_KEY_URL=
                PLUGIN_PACKAGES_REPO_NAME=
                PLUGIN_PACKAGES_REPO_URL=
                PLUGIN_PACKAGES=
                ;;
            microsoft)
                PACKAGES_KEY_URL=
                PACKAGES_REPO_NAME=
                PACKAGES_REPO_URL=
                PACKAGES="${PROJECT_BIN}"
                REQUIRED_PACKAGES_KEY_URL=
                REQUIRED_PACKAGES_REPO_NAME=
                REQUIRED_PACKAGES_REPO_URL=
                REQUIRED_PACKAGES=
                PLUGIN_PACKAGES_KEY_URL=
                PLUGIN_PACKAGES_REPO_NAME=
                PLUGIN_PACKAGES_REPO_URL=
                PLUGIN_PACKAGES=
                ;;
            *) ;;
        esac

        PROJECT_BIN_URL=                                                                                                                       # "https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases/download/${PACKAGE_VERSION}/${PROJECT_BIN}_${OS}-${ARCH}"
        PROJECT_TAR_URL=                                                                                                                       # "https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases/download/${PACKAGE_VERSION}/${PROJECT_BIN}-${PACKAGE_VERSION}-${OS}-${ARCH}.tar.gz"
        PROJECT_BZ2_URL=                                                                                                                       # "https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases/download/${PACKAGE_VERSION}/${PROJECT_BIN}-${PACKAGE_VERSION}-${OS}-${ARCH}.bz2"
        PROJECT_XZ_URL=                                                                                                                        # "https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases/download/${PACKAGE_VERSION}/${PROJECT_BIN}-${PACKAGE_VERSION}-${OS}-${ARCH}.xz"
        PROJECT_RAR_URL=                                                                                                                       # "https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases/download/${PACKAGE_VERSION}/${PROJECT_BIN}-${PACKAGE_VERSION}-${OS}-${ARCH}.rar"
        PROJECT_ZIP_URL="https://releases.hashicorp.com/${PROJECT_BIN}/${PACKAGE_VERSION}/${PROJECT_BIN}_${PACKAGE_VERSION}_${OS}_${ARCH}.zip" # "https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases/download/${PACKAGE_VERSION}/${PROJECT_BIN}-${PACKAGE_VERSION}-${OS}-${ARCH}.zip"
        INSTALL_SCRIPT_URL=                                                                                                                    # "https://get.${GITHUB_PROJECT}.io" | "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_PROJECT}/master/bin/install.sh"
        PKILL_SCRIPT_URL=                                                                                                                      # "https://get.${GITHUB_PROJECT}.io" | "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_PROJECT}/master/bin/pkillall.sh"
        UNINSTALL_SCRIPT_URL=                                                                                                                  # "https://get.${GITHUB_PROJECT}.io" | "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_PROJECT}/master/bin/uninstall.sh"
        INSTALL_SCRIPT_RUN_PARAMETERS=
        UNINSTALL_SCRIPT_RUN_PARAMETERS=
        # https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases
        PROJECT_GO_URL="github.com/${GITHUB_USER}/${GITHUB_PROJECT}/cmd/${PROJECT_BIN}"
        PROJECT_GO_BIN=${PROJECT_BIN}
        PROJECT_GO_BIN_RUN_PARAMETERS=
        # https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases
        PROJECT_NPM_BIN=${PROJECT_BIN}
        PROJECT_NPM_BIN_RUN_PARAMETERS_RUN_PARAMETERS=
        # https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases
        PROJECT_PYTHON_PACKAGES=${PROJECT_BIN}
        PROJECT_PYTHON_BIN=${PROJECT_BIN}
        PROJECT_PYTHON_BIN_RUN_PARAMETERS_RUN_PARAMETERS=
        # https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/releases
        DOCKER_REGISTRY=
        DOCKER_USER=${GITHUB_USER}
        DOCKER_PROJECT=${GITHUB_PROJECT}
        DOCKER_TAG=latest # latest | latest-alpine | v0.0.1 | $(cd ${HOME}/src/github.com/${GITHUB_USER}/${GITHUB_PROJECT}; git log --pretty=format:'%h' -n 1 | cat) | $(cd ${HOME}/src/github.com/${GITHUB_USER}/${GITHUB_PROJECT}; git log --pretty=format:'%H' -n 1 | cat)
        OFFICIAL_DOCKER_REGISTRY=
        OFFICIAL_DOCKER_USER=
        OFFICIAL_DOCKER_PROJECT=
        OFFICIAL_DOCKER_TAG=latest
        DOCKER_PARAMETERS=
        DOCKER_COMMAND=${PROJECT_BIN}

        EXTENSION= # a | b
    fi
}

function set_deployment_settings() {
    if [ "$#" != "0" ] && [ "$#" != "5" ]; then
        log_e "Usage: ${FUNCNAME[0]} [<LOCATION> <PLATFORM> <PLATFORM_DISTRO> <RUNTIME> <SSH_USER> <SSH_GROUP>]"
    else
        log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        if [ "$#" == "5" ]; then
            LOCATION="${1}"
            PLATFORM="${2}"
            PLATFORM_DISTRO="${3}"
            RUNTIME="${4}"
            SSH_USER="${5}"
            SSH_GROUP="${6}"
            SSH_USER_PASSWORD= # linux
            SSH_USER_PEM=
        else
            LOCATION=${LOCATION:-remote}
            PLATFORM=${PLATFORM:-libvirt}
            PLATFORM_DISTRO=${PLATFORM_DISTRO:-centos} # centos | ubuntu | mos
            RUNTIME=${RUNTIME:-daemon}
            SSH_USER=${PLATFORM_DISTRO}         # centos | ubuntu | mos
            SSH_GROUP=${SSH_GROUP:-remotes_env} # remotes | remotes_env | remotes_mos
            SSH_USER_PASSWORD=                  # linux
            SSH_USER_PEM=
        fi
        echo ">>> SSH_USER/SSH_PASSWORD/SSH_USER_PEM: ${SSH_USER}/${SSH_PASSWORD}/${SSH_USER_PEM}"
        echo ">>> Location/Platform/Distribution/Runtime: ${LOCATION}/${PLATFORM}/${PLATFORM_DISTRO}/${RUNTIME}"

        INFRASTRUCTURE_DEPLOYMENT_PROJECT=terraform_env                                                                                                  # terraform_env | terraform_mos
        INFRASTRUCTURE_DEPLOYMENT_PROJECT_TOP_DIR="${HOME}/Documents/myProject/Development/terraform/src/terraform/${INFRASTRUCTURE_DEPLOYMENT_PROJECT}" # ${TOP_DIR:?} | ${HOME}/Documents/myProject/Development/terraform/src/terraform/${INFRASTRUCTURE_DEPLOYMENT_PROJECT}
        DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR=${INFRASTRUCTURE_DEPLOYMENT_PROJECT_TOP_DIR}/providers/${PLATFORM}/${PLATFORM_DISTRO}
        CONFIGURATION_MANAGEMENT_TOP_DIR=${TOP_DIR:?}/inventories/${PLATFORM}/${PLATFORM_DISTRO} # ${TOP_DIR:?}
        REMOTE_CONFIGURATION_MANAGEMENT_TOP_DIR=/home/${SSH_USER}/inventories/${PLATFORM}/${PLATFORM_DISTRO}
        mkdir -p "${INFRASTRUCTURE_DEPLOYMENT_PROJECT_TOP_DIR}"
        mkdir -p "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}"
        mkdir -p "${CONFIGURATION_MANAGEMENT_TOP_DIR}"
        echo ">>> INFRASTRUCTURE_DEPLOYMENT_PROJECT_TOP_DIR=${INFRASTRUCTURE_DEPLOYMENT_PROJECT_TOP_DIR}"
        echo ">>> DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR=${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}"
        echo ">>> CONFIGURATION_MANAGEMENT_TOP_DIR=${CONFIGURATION_MANAGEMENT_TOP_DIR}"
        echo ">>> REMOTE_CONFIGURATION_MANAGEMENT_TOP_DIR=${REMOTE_CONFIGURATION_MANAGEMENT_TOP_DIR}"
        # STACK_NAME= # env | mos | my-cluster
        # echo ">>> STACK_NAME=${STACK_NAME}"
        # NEW_ROLE=
        # echo ">>> NEW_ROLE=${NEW_ROLE}"
        # CRI= # crio docker containerd
        # CNI= # calico cilium contiv-vpp flannel kube-router weave-net
        # CSI= # daemon container kubernetes
        # echo ">>> CRI=${CRI}"
        # echo ">>> CNI=${CNI}"
        # echo ">>> CSI=${CSI}"

        RESET_CONFIG=false
        RESET_SCRIPT=true
    fi
}

function dry_run() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_DIR>"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        echo -e "\n>>> Deploy Nodes...\n"

        rm -rf "${HOME}/.ssh/known_hosts"
        cd "${1}" || exit 1
        if [ ! -e "terraform.tfvars" ]; then
            cp terraform.tfvars.example terraform.tfvars
        fi
        ${USER_BIN}/terraform init
        terraform validate .
        ${USER_BIN}/terraform plan
        check_run_state $?
    fi
}

function show_terraform_state() {
    if [ "$#" != "1" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_DIR> [<TFSTATE_DIR>]"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        echo -e "\n>>> Show Terraform state in ${1}...\n"

        cd "${1}" || exit 1
        ${USER_BIN}/terraform output
    fi
}

function clean_runtime() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        cd "${TOP_DIR:?}" || exit 1

        sudo rm -rf /tmp/terraform-provider-libvirt-pool-*
        # sudo rm -rf ${ETC}/libvirt/qemu/*
        # sudo rm -rf /var/lib/libvirt/*
        sudo find ${ETC}/libvirt -name mos* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name centos* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name debian* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name fedora* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name opensuse* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name rancher* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name raspios* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name sles* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name ubuntu* -exec rm -rf {} \;
        sudo find ${ETC}/libvirt -name leap15* -exec rm -rf {} \;
        sudo rm -rf ${ETC}/libvirt/qemu/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}-*.xml
        sudo rm -rf ${ETC}/libvirt/qemu/networks/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}.xml
        sudo rm -rf ${ETC}/libvirt/qemu/networks/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}-network.xml
        sudo rm -rf ${ETC}/libvirt/qemu/networks/autostart/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}.xml
        sudo rm -rf ${ETC}/libvirt/qemu/networks/autostart/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}-network.xml
        sudo rm -rf ${ETC}/libvirt/storage/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}.xml
        sudo rm -rf ${ETC}/libvirt/storage/autostart/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}.xml
        STACK_NAME=my-cluster
        sudo rm -rf ${HOME}/.config/libvirt/qemu/networks/${STACK_NAME}-network.xml

        sudo rm -rf ${HOME}/Documents/myImages/libvirt/images
        sudo mkdir -p ${HOME}/Documents/myImages/libvirt/images
        sudo ls -alh ${HOME}/Documents/myImages/libvirt/images
        sudo rm -rf /var/lib/libvirt/dnsmasq/{mos,alpine,centos,debian,fedora,opensuse-leap,opensuse-tumbleweed,rancher-k3os,rancher-os,raspios,sles,ubuntu,leap15}-network.*
        sudo rm -rf /var/lib/libvirt/qemu/domain-*
        # VM_IMAGE_DIR=/var/lib/libvirt/images
        # ALT_VM_IMAGE_DIR=${HOME}/Documents/myImages/libvirt/images
        # sudo rm -rf ${VM_IMAGE_DIR}
        # sudo mkdir -p "${ALT_VM_IMAGE_DIR}"
        # sudo ln -s "${ALT_VM_IMAGE_DIR}" "${VM_IMAGE_DIR}"
        sudo rm -rf /var/log/libvirt/qemu/*
    fi
}

function clean_project() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        cd "${TOP_DIR:?}" || exit 1

        # find . -name "\.terraform*" -exec rm -rf {} \;
        find . -name "terraform.tfstate*" -exec rm -rf {} \;

        clean_runtime
    fi
}

function list_local_images() {
    if [ "$#" != "0" ]; then
        log_e "Usage: ${FUNCNAME[0]} <ARGS>"
    else
        # log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        # find / -name *.iso 2>/dev/null
        # find / -name *.qcow2 2>/dev/null
        # find / -name *.img 2>/dev/null
        # find / -name *.vmdk 2>/dev/null

        echo -e "\n>>> kvm/alpine...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/alpine/ || true
        echo -e "\n>>> kvm/centos...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/centos/ || true
        echo -e "\n>>> kvm/cirros...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/cirros/ || true
        echo -e "\n>>> kvm/debian...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/debian/ || true
        echo -e "\n>>> kvm/fedora...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/fedoara/ || true
        echo -e "\n>>> kvm/opensuse leap...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/opensuse-leap/ || true
        echo -e "\n>>> kvm/opensuse tumbleweed...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/opensuse-tumbleweed/ || true
        echo -e "\n>>> kvm/rancher k3os...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/rancher-k3os/ || true
        echo -e "\n>>> kvm/rancher os...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/rancher-os/ || true
        echo -e "\n>>> kvm/raspios...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/raspios/ || true
        echo -e "\n>>> kvm/SLES...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/sles/ || true
        echo -e "\n>>> kvm/ubuntu...\n"
        ls -alh ${HOME}/Documents/myImages/kvm/ubuntu/ || true
        echo -e "\n>>> /var/lib/libvirt/images...\n"
        sudo ls -alh /var/lib/libvirt/images || true
        echo -e "\n>>> ${HOME}/Documents/myImages/libvirt/images...\n"
        sudo ls -alh ${HOME}/Documents/myImages/libvirt/images || true

        echo -e "\n>>> ${ETC}/libvirt...\n"
        sudo ls -alh ${ETC}/libvirt/qemu || true
        sudo ls -alh ${ETC}/libvirt/qemu/networks || true
        sudo ls -alh ${ETC}/libvirt/qemu/networks/autostart || true
        sudo ls -alh ${ETC}/libvirt/storage || true
        sudo ls -alh ${ETC}/libvirt/storage/autostart || true
        # sudo rm -rf /var/lib/libvirt/dnsmasq/*-network.pi*
        # sudo ls -alh /var/lib/libvirt/dnsmasq || true

        echo -e "\n>>> /tmp/terraform-provider-libvirt-pool-*...\n"
        sudo ls -l /tmp/terraform-provider-libvirt-pool-* || true

        # ls -alh ${HOME}/.cache/libvirt/

    fi
}

function ssh_to() {
    if [ "$#" != "1" ] && [ "$#" != "2" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR> [<INSTANCES_TYPE>]"
    else
        log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        clear
        cd "${1}" || exit 1
        SSH_USER=$(terraform output username)
        if [ "${SSH_USER}" == "" ]; then
            select_x_from_array "${DISTROS} rancher root ec2-user" "SSH_USER" SSH_USER # mos
        fi

        if [ "$#" == "2" ]; then
            IP_INSTANCES=$(terraform output ${2} | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
            select_x_from_array "${IP_INSTANCES}" "IP" IP
        else
            case ${INFRASTRUCTURE_DEPLOYMENT_PROJECT} in
                terraform_env)
                    IP_ETCDS=$(terraform output ip_etcds | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_STORAGES=$(terraform output ip_storages | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_MASTERS=$(terraform output ip_masters | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_WORKERS=$(terraform output ip_workers | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IPS="${IP_ETCDS[*]} ${IP_STORAGES[*]} ${IP_MASTERS[*]} ${IP_WORKERS[*]}"
                    echo ">>> IPS: ${#IPS[*]} ${IPS}"
                    ;;
                terraform_mos)
                    IP_ALPINES=$(terraform output ip_alpines | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_CENTOSS=$(terraform output ip_centoss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_CIRROSS=$(terraform output ip_cirross | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_DEBIANS=$(terraform output ip_debians | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_FEDORAS=$(terraform output ip_fedoras | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_OPENSUSE_LEAPS=$(terraform output ip_opensuse_leaps | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_OPENSUSE_TUMBLEWEEDS=$(terraform output ip_opensuse_tumbleweeds | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RANCHER_HARVESTERS=$(terraform output ip_rancher_harvesters | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RANCHER_K3OSS=$(terraform output ip_rancher_k3oss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RANCHER_OSS=$(terraform output ip_rancher_oss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RASPIOS=$(terraform output ip_raspioss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_SLESS=$(terraform output ip_sless | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_UBUNTUS=$(terraform output ip_ubuntus | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IPS="${IP_ALPINES} ${IP_CENTOSS[*]} ${IP_CIRROSS[*]} ${IP_DEBIANS[*]} ${IP_FEDORAS[*]} ${IP_OPENSUSE_LEAPS[*]} ${IP_OPENSUSE_TUMBLEWEEDS[*]} ${IP_RANCHER_HARVESTERS[*]} ${IP_RANCHER_K3OSS[*]} ${IP_RANCHER_OSS[*]} ${IP_RASPIOSS[*]} ${IP_SLESS[*]} ${IP_UBUNTUS[*]}"
                    echo ">>> IPS: ${#IPS[*]} ${IPS}"
                    ;;
                *) ;;
            esac
            select_x_from_array "${IPS}" "IP" IP
        fi

        echo "${SSH_USER}" "${IP}"
        ssh_cmd "${SSH_USER}" "${IP}"
    fi
}

function ssh_command() {
    if [ "$#" != "1" ] && [ "$#" != "2" ]; then
        log_e "Usage: ${FUNCNAME[0]} <DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR> [<INSTANCES_TYPE>]"
    else
        log_m "${FUNCNAME[0]} ${*}"
        # cd "${TOP_DIR:?}" || exit 1

        clear
        cd "${1}" || exit 1
        SSH_USER=$(terraform output username)
        if [ "${SSH_USER}" == "" ]; then
            select_x_from_array "${DISTROS} rancher root ec2-user" "SSH_USER" SSH_USER # "mos"
        fi

        if [ "$#" == "2" ]; then
            IPS=$(terraform output ${2} | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
        else
            case ${INFRASTRUCTURE_DEPLOYMENT_PROJECT} in
                terraform_env)
                    IP_ETCDS=$(terraform output ip_etcds | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_STORAGES=$(terraform output ip_storages | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_MASTERS=$(terraform output ip_masters | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_WORKERS=$(terraform output ip_workers | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IPS="${IP_ETCDS[*]} ${IP_STORAGES[*]} ${IP_MASTERS[*]} ${IP_WORKERS[*]}"
                    echo ">>> IPS: ${#IPS[*]} ${IPS}"
                    ;;
                terraform_mos)
                    IP_ALPINES=$(terraform output ip_alpines | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_CENTOSS=$(terraform output ip_centoss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_CIRROSS=$(terraform output ip_cirross | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_DEBIANS=$(terraform output ip_debians | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_FEDORAS=$(terraform output ip_fedoras | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_OPENSUSE_LEAPS=$(terraform output ip_opensuse_leaps | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_OPENSUSE_TUMBLEWEEDS=$(terraform output ip_opensuse_tumbleweeds | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RANCHER_HARVESTERS=$(terraform output ip_rancher_harvesters | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RANCHER_K3OSS=$(terraform output ip_rancher_k3oss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RANCHER_OSS=$(terraform output ip_rancher_oss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_RASPIOS=$(terraform output ip_raspioss | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_SLESS=$(terraform output ip_sless | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IP_UBUNTUS=$(terraform output ip_ubuntus | cut -d "=" -f 2 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | sed ':a;N;$!ba;s/\n/ /g' | tr -d '{' | tr -d '}' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' | tr -d '"')
                    IPS="${IP_ALPINES} ${IP_CENTOSS[*]} ${IP_CIRROSS[*]} ${IP_DEBIANS[*]} ${IP_FEDORAS[*]} ${IP_OPENSUSE_LEAPS[*]} ${IP_OPENSUSE_TUMBLEWEEDS[*]} ${IP_RANCHER_HARVESTERS[*]} ${IP_RANCHER_K3OSS[*]} ${IP_RANCHER_OSS[*]} ${IP_RASPIOSS[*]} ${IP_SLESS[*]} ${IP_UBUNTUS[*]}"
                    echo ">>> IPS: ${#IPS[*]} ${IPS}"
                    ;;
                *) ;;
            esac
        fi

        echo "${SSH_USER}" "${IPS}"
        # local COMMANDS='uname -s; uname -m; echo; cat /etc/*-release | uniq -u; echo; hostnamectl'
        # local COMMANDS='uname -s | tr A-Z a-z;'
        # local COMMANDS='uname -m | sed s/x86_64/amd64/;'
        # local COMMANDS='cat /etc/*-release | uniq -u | grep ^ID= | cut -d = -f 2 | sed s/\"//g;'
        # local COMMANDS='command -v {apk,apt-get,brew,dnf,emerge,pacman,yum,zypper,xbps-install} 2>/dev/null;'
        # local COMMANDS='command -v {apk,dpkg,pkgbuild,rpm} 2>/dev/null;'
        # local COMMANDS='command -v {curl,wget} 2>/dev/null;'
        # local COMMANDS='command -v {tar,unzip} 2>/dev/null;'
        # local COMMANDS='OS=$(uname -s | tr A-Z a-z);ARCH=$(uname -m | sed s/x86_64/amd64/);DISTRO=$(cat /etc/*-release | uniq -u | grep ^ID= | cut -d = -f 2 | sed s/\"//g);PACKAGE_MANAGER=$(basename $(command -v {apk,apt-get,brew,dnf,emerge,pacman,yum,zypper,xbps-install} 2>/dev/null));PACKAGE_SYSTEM=$(basename $(command -v {apk,dpkg,pkgbuild,rpm} 2>/dev/null));echo "${OS} ${ARCH} ${DISTRO} ${PACKAGE_MANAGER} ${PACKAGE_SYSTEM}"'
        local COMMANDS='. /etc/os-release && echo "${ID} ${VERSION_ID} ${VERSION}"'
        for IP in ${IPS[*]}; do
            # echo -e "\n>>> ${IP}...\n"
            ssh_cmd "${SSH_USER}" "${IP}" "${COMMANDS}"
        done
    fi
}

#******************************************************************************
# Selection Parameters

if [ "${ACTION}" == "" ]; then
    MAIN_OPTIONS="create_project_skeleton clean_project \
        start_runtime stop_runtime \
        dry_run deploy_infrastructure undeploy_infrastructure install_infrastructure_requirements uninstall_infrastructure_requirements \
        install update upgrade uninstall \
        configure remove_configurations \
        clean_runtime clean_project \
        list_local_images \
        ssh_to ssh_command \
        ssh_to_lb ssh_to_etcd ssh_to_storage ssh_to_master ssh_to_worker \
        show_infrastructure_status show_k8s_status show_app_status \
        access_service access_service_by_proxy ssh_to_node ssh_command \
        status get_version lint build"

    select_x_from_array "${MAIN_OPTIONS}" "Action" ACTION # "a"
fi

# if [ "${XXX}" == "" ]; then
#     # select_x_from_array "a b c" "XXX" XXX # "a"
#     read_and_confirm "XXX MSG" XXX # "XXX set value"
# fi

set_packages_by_distribution
set_deployment_settings # "${LOCATION}" "${PLATFORM}" "${PLATFORM_DISTRO}" "${RUNTIME}" "${SSH_USER}"

PRINT_CLOUD_INIT_LOG=false
# USER_BIN=/usr/local/opt/terraform@0.12/bin

#******************************************************************************
# Main Program

# update_datetime
source_rc "${DISTRO}" "${PLATFORM}"
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

    start_runtime)
        start_runtime
        ;;

    stop_runtime)
        stop_runtime
        ;;

    dry_run)
        if [ "${PLATFORM}" == "libvirt" ]; then
            start_runtime
        fi
        dry_run "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}"
        ;;

    deploy_infrastructure)
        if [ "${PLATFORM}" == "libvirt" ]; then
            start_runtime
        fi
        find ${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR} -name linux_amd64 -exec chmod -R +x {} \;
        deploy_infrastructure "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "${PLATFORM}" "${PLATFORM_DISTRO}"
        ;;

    undeploy_infrastructure)
        find ${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR} -name linux_amd64 -exec chmod -R +x {} \;
        undeploy_infrastructure "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "${PLATFORM}" "${PLATFORM_DISTRO}"
        ;;

    install_infrastructure_requirements)
        install_infrastructure_requirements # "${PLATFORM}" "${PLATFORM_DISTRO}"
        ;;

    uninstall_infrastructure_requirements)
        uninstall_infrastructure_requirements # "${PLATFORM}" "${PLATFORM_DISTRO}"
        ;;

    install)
        # install_requirements # ${GITHUB_USER} ${GITHUB_PROJECT} ${PACKAGE_VERSION} ${OS} ${ARCH} ${PROJECT_BIN}
        ${HOME}/Documents/myProject/Development/terraform/src/bash/bash_terraform/cmd.sh -a install
        ${HOME}/Documents/myProject/Development/terraform/src/bash/bash_terraform_provider_libvirt/cmd.sh -a install
        # install_plugins # ${GITHUB_USER} ${GITHUB_PROJECT} ${PACKAGE_VERSION} ${OS} ${ARCH} ${PROJECT_BIN}
        ;;

    uninstall)
        # uninstall_plugins # ${GITHUB_USER} ${GITHUB_PROJECT} ${PACKAGE_VERSION} ${OS} ${ARCH} ${PROJECT_BIN}
        ${HOME}/Documents/myProject/Development/terraform/src/bash/bash_terraform_provider_libvirt/cmd.sh -a uninstall
        ${HOME}/Documents/myProject/Development/terraform/src/bash/bash_terraform/cmd.sh -a uninstall
        # uninstall_requirements # ${GITHUB_USER} ${GITHUB_PROJECT} ${PACKAGE_VERSION} ${OS} ${ARCH} ${PROJECT_BIN}
        ;;

    configure)
        configure
        ;;

    remove_configurations)
        remove_configurations
        ;;

    clean_project)
        if [ "${PLATFORM}" == "libvirt" ]; then
            stop_runtime
        fi
        clean_project
        ;;
    clean_runtime)
        if [ "${PLATFORM}" == "libvirt" ]; then
            stop_runtime
        fi
        clean_runtime
        ;;

    list_local_images)
        list_local_images
        ;;

    status)
        show_terraform_state "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}"
        ;;

    get_version)
        get_version # ${PROJECT_BIN}
        ;;

    ssh_to)
        ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" # "ip_instances"
        ;;
    ssh_command)
        ssh_command "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" # "ip_instances"
        ;;

    ssh_to_lb)
        ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "ip_load_balancer"
        ;;

    ssh_to_etcd)
        ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "ip_etcds"
        # ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "etcds_public_ip"
        ;;
    ssh_to_storage)
        ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "ip_storages"
        # ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "storages_public_ip"
        ;;
    ssh_to_master)
        ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "ip_masters"
        # ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "masters_public_ip"
        ;;
    ssh_to_worker)
        ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "ip_workers"
        # ssh_to "${DEPLOYMENT_PLATFORM_DISTRO_TOP_DIR}" "workers_public_ip"
        ;;

    *)
        # Others / Unknown Option
        usage
        ;;
esac

# find "${TOP_DIR:?}" -type d -name bin -exec sh -c "rm -rf {}" {} \;

#******************************************************************************
#set +e # Exit on error Off
#set +x # Trace Off
#echo "End: $(basename "${0}")"
echo -e "\n================================================================================\n"
exit 0
#******************************************************************************
