#!/bin/bash

set -ex

declare -A FORGE_MODULES
declare -A SOURCE_MODULES
declare -A INTEGRATION_MODULES

MODULE_PATH=`puppet config print modulepath | cut -d ':' -f 1`
OPENSTACK_GIT_ROOT=https://git.openstack.org
GIT_CMD_BASE="git --git-dir=${MODULE_PATH}/${MODULE_NAME}/.git --work-tree ${MODULE_PATH}/${MODULE_NAME}"
SCRIPT_DIR=$(readlink -f "$(dirname $0)")

cat > clonemap.yaml <<EOF
clonemap:
  - name: '(.*?)/puppet-(.*)'
    dest: '/etc/puppet/modules/\2'
EOF

project_names=""
source ${SCRIPT_DIR}/modules.env

for MOD in ${!FORGE_MODULES[*]} ; do
  echo $MOD
  puppet module install $MOD --version=${FORGE_MODULES[$MOD]}
done

for MOD in ${!SOURCE_MODULES[*]} ; do
  echo $MOD
  MODULE_NAME=`echo $MOD | awk -F- '{print $NF}'`
  GIT_CMD_BASE="git --git-dir=${MODULE_PATH}/${MODULE_NAME}/.git --work-tree ${MODULE_PATH}/${MODULE_NAME}"
  `${GIT_CMD_BASE} clone $MOD`
done

for MOD in ${!INTEGRATION_MODULES[*]} ; do
  echo $MOD
  OPENSTACK_GIT_ROOT=https://git.openstack.org
  MODULE_NAME=`echo $MOD | awk -F- '{print $NF}'`
  GIT_CMD_BASE="git --git-dir=${MODULE_PATH}/${MODULE_NAME}/.git --work-tree ${MODULE_PATH}/${MODULE_NAME}"
  `${GIT_CMD_BASE} clone ${OPENSTACK_GIT_ROOT}/${MOD}`
done
