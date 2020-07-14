#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

function prepare {
  sudo chown -R root:root /tmp/saltstack
  apply_amazonlinux_salt_patch
}

function copy_resources {
  local saltenv=${1}
  sudo mkdir -p /srv/salt/${saltenv} /srv/pillar/${saltenv}
  sudo cp -R /tmp/saltstack/${saltenv}/salt/* /srv/salt/${saltenv}
  if [ -d "/tmp/saltstack/${saltenv}/pillar" ]
  then
    sudo cp -R /tmp/saltstack/${saltenv}/pillar/* /srv/pillar/${saltenv}
  fi
}
  #Needed because of https://github.com/saltstack/salt/issues/47258
function apply_amazonlinux_salt_patch {
  if [ "${OS}" == "amazonlinux" ] && [ -f /tmp/saltstack/config/minion ] && ! grep -q "rh_service" /tmp/saltstack/config/minion ; then
    tee -a /tmp/saltstack/config/minion << EOF
providers:
  service: rh_service
EOF
  fi
}

function highstate {
  local saltenv=${1}
  copy_resources ${saltenv}
  ${SALT_PATH}/bin/salt-call --local state.highstate saltenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --log-file-level=info --config-dir=/tmp/saltstack/config
}

function apply_optional_states {
  echo "Running applying optional states: ${OPTIONAL_STATES}"

  if [ -n "${OPTIONAL_STATES}" ]
  then
    local saltenv="optional"
    copy_resources ${saltenv}
    ${SALT_PATH}/bin/salt-call --local state.sls ${OPTIONAL_STATES} saltenv=${saltenv} pillarenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --config-dir=/tmp/saltstack/config
  fi
}

# This adds entities to the 'roles' key to be used during actual cluster install. Hence, this does not use the temporary config location.
function add_single_role_for_cluster_salt {
  local role=${1}
  ${SALT_PATH}/bin/salt-call --local grains.append roles ${role} -l info --log-file=/tmp/salt-build-${saltenv}.log --log-file-level=debug
}

function add_prewarmed_roles {
  if [ "${INCLUDE_FLUENT}" == "Yes" ]; then
    # Note: This will need to be changed if making changes to versions etc in the prewarmed image.
    local fluent_prewarmed="fluent_prewarmed_v1"
    echo "Adding ${fluent_prewarmed} to the list of roles for the final image"
    add_single_role_for_cluster_salt ${fluent_prewarmed}
  fi

  if  [ "${STACK_TYPE}" == "CDH" -a ! -z "${CLUSTERMANAGER_VERSION}" -a ! -z "${CLUSTERMANAGER_BASEURL}" -a ! -z "${CLUSTERMANAGER_GPGKEY}" -a ! -z "${STACK_VERSION}" -a ! -z "${STACK_BASEURL}" -a ! -z "${STACK_REPOID}" ]; then
    local prewarmed="prewarmed_v1"
    echo "Adding ${prewarmed} to the list of roles for the final image"
    add_single_role_for_cluster_salt ${prewarmed}
  fi
}

function create_archives_and_delete_files() {
  tar -C /usr/lib64 -cvzf /usr/lib64/python3.6-archive.tar.gz python3.6
  tar -C /usr/lib -cvzf /usr/lib/python3.6-archive.tar.gz python3.6
  tar -C /usr/lib64 -cvzf /usr/lib64/python2.7-archive.tar.gz python2.7
  tar -C /usr/lib -cvzf /usr/lib/python2.7-archive.tar.gz python2.7

  # Salt (version as of this change: 3000.2) ends up taking a long time to load modules. vspere is an especially slow one taking 3 seconds.
  # Salt does not seem to allow skipping module load ('disable_modules' only disables module usage, not module loading)
  # So, deleting some modules which are not used, and tend to cause Exceptions / delays
  find /opt/salt_3000.2 | grep modules | grep lxd | xargs rm
  find /opt/salt_3000.2 | grep modules | grep vsphere | xargs rm
  find /opt/salt_3000.2 | grep modules | grep boto3_elasticsearch | xargs rm
  find /opt/salt_3000.2 | grep modules | grep win_ | xargs rm

  tar -C /opt -cvzf /opt/salt_${SALT_VERSION}-archive.tar.gz salt_${SALT_VERSION}

  echo "Removing salt,td-agent and python3.6 in favor of archives"
  rm -fr /opt/salt_3000.2
  tar -C /opt -cvzf /opt/td-agent-archive.tar.gz td-agent
  rm -fr /opt/td-agent
  rm -fr /usr/lib64/python3.6
  rm -fr /usr/lib/python3.6
  # Not removing python2.7 since it is used by cloud-init
}


: ${CUSTOM_IMAGE_TYPE:=$1}

case ${CUSTOM_IMAGE_TYPE} in
  base|"")
    echo "Running highstate for Base.."
    prepare
    highstate "base"
  ;;
  freeipa)
    echo "Running highstate for FreeIPA.."
    prepare
    highstate "base"
    highstate "freeipa"
  ;;
  hortonworks)
    echo "Running highstate for Base and Hortonworks.."
    prepare
    highstate "base"
    highstate "hortonworks"
  ;;
  *)
    echo "Unsupported CUSTOM_IMAGE_TYPE:" ${CUSTOM_IMAGE_TYPE}
    exit 1
  ;;
esac



apply_optional_states

echo "Adding prewarmed roles for salt used in final image"
add_prewarmed_roles

echo "Running validation and cleanup"
highstate "final"

echo "Creating archives for extraction at image startup, and deleting files"
create_archives_and_delete_files
