#!/bin/bash

set -ex

export SCRIPT_DIR=$(readlink -f "$(dirname $0)")
export PUPPETFILE_DIR=/etc/puppet/modules
export PUPPETFILE=${SCRIPT_DIR}/Puppetfile

gem install r10k --no-ri --no-rdoc
r10k puppetfile install -v

# If zuul-cloner is there, have it reinstall modules using zuul refs
# This may be extracted out to JJB later
if [ -e /usr/zuul-env/bin/zuul-cloner ] ; then
  cat > clonemap.yaml <<EOF
clonemap:
  - name: '(.*?)/puppet-(.*)'
    dest: '/etc/puppet/modules/\2'
EOF
  project_names=$(
    awk '/START OpenStack/,/END OpenStack/ {
      if ($1 == ":git")
        print $3
    } ' ${SCRIPT_DIR}/Puppetfile | tr -d "'," | cut -d '/' -f 4- | xargs
  )

  /usr/zuul-env/bin/zuul-cloner -m clonemap.yaml \
    --cache-dir /opt/git \
    --zuul-ref $ZUUL_REF \
    --zuul-branch $ZUUL_BRANCH \
    --zuul-url $ZUUL_URL \
    git://git.openstack.org $project_names

  # Temporary, used to show that zuul-clone worked
  git --git-dir ${PUPPETFILE_DIR}/openstacklib/.git log -1
fi
