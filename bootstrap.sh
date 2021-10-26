#!/bin/bash
set -eo pipefail

usage() {
  local script_name
  script_name=$(basename "${0}")
  echo "${script_name} -p[12] <username|pool_id> <password|git_url>"
  echo
  echo "${script_name} is intended to be run two times. First time"
  echo 'using argument -p1 to register the system and deal with the'
  echo 'subscription manager setup. Second time, using -p2 to finish'
  echo 'the system boostrap.'
}

checkIfWithinAppropriateNetwork() {
  local test_ip=${1}
  echo "Abort if not within Red Hat Network..."
  ping -c 5 "${test_ip}"
}

checkIfSystemHasBeenSubscribed() {
  system_status=$(subscription-manager | grep -e '^Status')
  if [ "${system_status}" = 'Not Subscribed' ]; then
    echo 'System is not subscribed, regenerate and try again.'
    subscription-manager identity --regenerate --force
    sleep 10
    checkIfSystemHasBeenSubscribed
  fi
}

registrationAndSubs() {
  local username=${1}
  local password=${2}

  subscription-manager register --username="${username}" --password="${password}" --name=olympus
  subscription-manager refresh
  subscription-manager attach --auto
  checkIfSystemHasBeenSubscribed
  echo "Available subs are registred into subs.list"
  subscription-manager list --available --all | tee subs.list
}

updateAndInstallReqs() {
  local pool_id=${1}
  local repo_to_enable=${2}

  subscription-manager attach --pool="${pool_id}"
  subscription-manager repos --enable "${repo_to_enable}"

  cat /etc/redhat-release
  yum update -y
  cat /etc/redhat-release
  yum install -y git ansible
  ansible-playbook --version
  git --version
}

setupAnsible() {
  mv /etc/ansible/ /etc/ansible.bck
  git clone "${ANSIBLE_GIT_URL}" /etc/ansible/
  cd /etc/ansible/
  git checkout "origin/${ANSIBLE_GIT_BRANCH}" -b "${ANSIBLE_GIT_BRANCH}"

  ansible-galaxy collection install -r requirements.yml
}

setupAnsibleVars() {
  checkIfWithinAppropriateNetwork "${NETWORK_TEST_IP}"
  git config --global http.sslVerify false
  git clone "${ANSIBLE_VARS_GIT_URL}" vars
  cd vars
  git checkout "origin/${ANSIBLE_GIT_BRANCH}" -b "${ANSIBLE_GIT_BRANCH}"
}

fixupUserUsingJenkinsUID() {
  local uid='1000'
  local guid='1000'
  local id_shift='666'
  local uid_file=/etc/passwd

  set -e
  res=$(grep -c -e "${uid}" ${uid_file} )
  if [ "${res}" -eq 1 ]; then
    username=$(echo "${res}" | cut -f1 -d: )
    echo "user ${username} already uses UID ${uid}. Kill all tied process before uid change..."
    pids=$(pgrep -u "${username}" )
    # shellcheck disable=SC2086
    kill ${pids}
    # shellcheck disable=SC2086
    kill -9 ${pids}
    set +e
    usermod -u $(( "${uid}" + "${id_shift}" )) "${username}"
    groupmod -g $(( "${guid}" + "${id_shift}" )) "${username}"
  fi

}

checkArgumentsWithPhase() {
  local expectedPhase=${1}

  if [ -n "${expectedPhase}" ]; then
      if [ -z "${phase}" ]; then
        phase="${expectedPhase}"
      fi

      if [ "${phase}" != "${expectedPhase}" ]; then
        echo "Conflicting argument, aborting".
        exit 1
      fi
   else
      echo "Inconsistent state."
      exit 2
   fi
}

checkArgument() {
  local value=${1}
  local msg=${2}
  local exitCode=${3:-'1'}

  if [ -z "${value}" ]; then
    echo "${msg}"
    exit "${exitCode}"
  fi
}

set +u

phase=""
while getopts hu:p:i:g: OPT; do
  case "$OPT" in
    h)
      usage
      exit 0
      ;;
    u)
      readonly USERNAME=${OPTARG}
      checkArgumentsWithPhase 'one'
      ;;
    p)
      readonly RHN_PASSWORD=${OPTARG}
      checkArgumentsWithPhase 'one'
      ;;
    i)
      readonly POOL_ID=${OPTARG}
      checkArgumentsWithPhase 'two'
      ;;
    g)
      readonly ANSIBLE_VARS_GIT_URL=${OPTARG}
      checkArgumentsWithPhase 'two'
      ;;
    *)
      echo "Unrecognized options:${OPTARG}"
      exit 1;
      ;;
  esac
done

readonly REPO_TO_ENABLE=${REPO_TO_ENABLE:-'ansible-2.9-for-rhel-8-x86_64-rpms'}
readonly NETWORK_TEST_IP=${NETWORK_TEST_IP:-'10.36.110.1'}
readonly ANSIBLE_GIT_URL=${ANSIBLE_GIT_URL:-'https://rpelisse@github.com/jboss-set/zeus.git'}
readonly ANSIBLE_GIT_BRANCH=${ANSIBLE_GIT_BRANCH:-'olympus'}
readonly ANSIBLE_MAIN_SCRIPT=${4:-'zeus.yml'}

set -u

checkArgument "${phase}" 'No phase selected' 3
if [ "${phase}" = 'one' ]; then
  checkArgument "${USERNAME}" "No RHN username provided - aborting" 4
  checkArgument "${RHN_PASSWORD}" "No RHN PASSWORD provided - aborting" 5
  registrationAndSubs "${USERNAME}" "${RHN_PASSWORD}"
fi

if [ "${phase}" = 'two' ]; then
  checkArgument "${POOL_ID}" "No pool id provided - aborting" 4
  checkArgument "${ANSIBLE_VARS_GIT_URL}" "Missing gitlab url - aborting" 5

  updateAndInstallReqs "${POOL_ID}" "${REPO_TO_ENABLE}"
  setupAnsible

  setupAnsibleVars
  fixupUserUsingJenkinsUID
  setenforce 0
  ansible-playbook "${ANSIBLE_MAIN_SCRIPT}"
fi
