#!/bin/bash

set -ex

declare -A FORGE_MODULES
declare -A SOURCE_MODULES
declare -A INTEGRATION_MODULES

MODULE_PATH=`puppet config print modulepath | cut -d ':' -f 1`
OPENSTACK_GIT_ROOT=https://git.openstack.org
GIT_CMD_BASE="git --git-dir=${MODULE_PATH}/${MODULE_NAME}/.git --work-tree ${MODULE_PATH}/${MODULE_NAME}"
SCRIPT_DIR=$(readlink -f "$(dirname $0)")

project_names=""
source ${SCRIPT_DIR}/modules.env

for MOD in ${!FORGE_MODULES[*]} ; do
  puppet module install $MOD --version=${FORGE_MODULES[$MOD]}
done

for MOD in ${!SOURCE_MODULES[*]} ; do
  MODULE_NAME=`echo $MOD | awk -F- '{print $NF}'`
  git clone $MOD ${MODULE_PATH}/${MODULE_NAME}
done

if [ -e /usr/zuul-env/bin/zuul-cloner ] ; then
  cat > clonemap.yaml <<EOF
clonemap:
  - name: '(.*?)/puppet-(.*)'
    dest: '/etc/puppet/modules/\2'
EOF
  project_names=""
  for MOD in ${!INTEGRATION_MODULES[*]} ; do
    project_names+=" $MOD"
  done
  /usr/zuul-env/bin/zuul-cloner -m clonemap.yaml \
    --cache-dir /opt/git \
    --zuul-ref $ZUUL_REF \
    --zuul-branch $ZUUL_BRANCH \
    --zuul-url $ZUUL_URL \
    git://git.openstack.org $project_names
  git --git-dir ${MODULE_PATH}/$(echo $project_names | cut -d ' ' -f 1 | cut -d '-' -f 2)/.git log -1
else
  for MOD in ${!INTEGRATION_MODULES[*]} ; do
    OPENSTACK_GIT_ROOT=https://git.openstack.org
    MODULE_NAME=`echo $MOD | awk -F- '{print $NF}'`
    git clone ${OPENSTACK_GIT_ROOT}/${MOD} ${MODULE_PATH}/${MODULE_NAME}
  done
fi
