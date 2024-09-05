########
# myrc #
########

source $WORKING_DIR/andrew-notes/term/ohmyzshrc.sh
# actually need to set up oh-my-posh last to override any previous theming configs
source $WORKING_DIR/andrew-notes/term/ohmyposhrc.sh

# set terminal width:
# export COLUMNS=2000

# let pasting line returns enter the command (setting it though iterm settings works well for large pastes, this does not)
# unset zle_bracketed_paste

# GO env vars:
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
PATH="$GOBIN:$PATH"

function copysshidfyre() {
  STACK_NAME=$1
  ssh-copy-id -f root@api.${STACK_NAME}.cp.fyre.ibm.com
  ocl $STACK_NAME
  oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
}

function clipfyrekubeadminpass() {
  STACK_NAME=$1
  getfyrekubeadminpass ${STACK_NAME} | pbcopy
}

# ssh and oc FUNCTIONS (Credits: Arie Sutiono)
function sshfyre() {
  STACK_NAME=$1
  ssh root@api.${STACK_NAME}.cp.fyre.ibm.com
}

function getfyrekubeadminpass() {
  STACK_NAME=$1
  ssh root@api.${STACK_NAME}.cp.fyre.ibm.com -C "cat /root/auth/kubeadmin-password"
}

function ocl() {
  STACK_NAME=$1
  NAMESPACE=$2
  KUBE_ADMIN_PASS=$3
  KUBE_ADMIN_USER=kubeadmin
  KUBECONFIGOLD=$KUBECONFIG
  export KUBECONFIG=$HOME/.kube/config_${STACK_NAME}
  if [[ "${KUBECONFIGOLD}" == "$HOME/.kube/config_${STACK_NAME}" ]] || [[ ! -f $KUBECONFIG ]]; then
    [[ $KUBE_ADMIN_PASS == '' ]] && KUBE_ADMIN_PASS=$(getfyrekubeadminpass $STACK_NAME 2>/dev/null)
    oc login -s https://api.$STACK_NAME.cp.fyre.ibm.com:6443 -u $KUBE_ADMIN_USER -p $KUBE_ADMIN_PASS -n $NAMESPACE --insecure-skip-tls-verify
  else
    if [[ $NAMESPACE != '' ]]; then
      oc project $NAMESPACE
    fi
  fi
}

function cpdclilogin() {
  STACK_NAME=$1
  KUBE_ADMIN_PASS=$2
  KUBE_ADMIN_USER=kubeadmin
  [[ $KUBE_ADMIN_PASS == '' ]] && KUBE_ADMIN_PASS=$(getfyrekubeadminpass $STACK_NAME)
  cpd-cli manage login-to-ocp --username=$KUBE_ADMIN_USER --password=$KUBE_ADMIN_PASS --server=https://api.$STACK_NAME.cp.fyre.ibm.com:6443
}

function getapikey() {
  NAMESPACE=$1
  ROUTE=$(oc get route cpd -n $NAMESPACE -o json | jq -r '.status.ingress[0].host')
  CP_ADMIN=$(oc get secret platform-auth-idp-credentials -o jsonpath="{.data.admin_username}" -n $NAMESPACE | base64 -d)
  CP_PASS=$(oc get secret platform-auth-idp-credentials -o jsonpath="{.data.admin_password}" -n $NAMESPACE | base64 -d)
  AUTH_TOKEN=$(curl -k -X POST -H "Content-Type: application/json" -d "{\"username\":\"${CP_ADMIN}\",\"password\":\"${CP_PASS}\"}" "https://${ROUTE}/icp4d-api/v1/authorize" | jq -r '.token')
  export API_KEY=$(curl -k -X GET "https://${ROUTE}/usermgmt/v1/user/apiKey" -H 'Accept: application/json' -H "Authorization: Bearer ${AUTH_TOKEN}" | jq -r '.apiKey')
  echo API_KEY=$API_KEY
}

function devinit() {
  # start podman
  podman machine start
}

function devstop() {
  # stop podman
  oc logout
  export KUBECONFIG=''
  rm $HOME/.kube/config_*
  podman machine stop
}

function devstart() {
  # $1 stack name
  # $2 namespace
  STACK_NAME=$1
  NAMESPACE=$2
  KUBE_ADMIN_PASS=$3

  # login to Open Shift, cpd-cli, and Podman
  ocl $STACK_NAME $NAMESPACE $KUBE_ADMIN_PASS 2>/dev/null
  cpdclilogin $STACK_NAME $KUBE_ADMIN_PASS 2>/dev/null
  podman login default-route-openshift-image-registry.apps.$STACK_NAME.cp.fyre.ibm.com -u kubeadmin -p $(oc whoami -t) --tls-verify=false
}

function devbuild() {
  # $1 stack name
  # $2 namespace

  # Start Dev
  STACK_NAME=$1
  NAMESPACE=$2
  devstart $STACK_NAME $NAMESPACE

  # BUILD & PUSH custom zen-watchdog image
  cd $WORKING_DIR/monitoring/zen-watchdog

  # tidy go
  go mod tidy

  # NOTE! only necessary initially and if you made changes to swagger api
  make swagger

  # build image (and stop if build failed)
  build_GOARCH=amd64 make docker-dev || {
    echo "ERROR: image build failed"
    exit
  }

  IMAGE_NAME=cpdbr-api
  IMAGE_TAG=master-x86_64
  podman tag localhost/$IMAGE_NAME:$IMAGE_TAG default-route-openshift-image-registry.apps.$STACK_NAME.cp.fyre.ibm.com/$NAMESPACE/$IMAGE_NAME:$IMAGE_TAG
  podman push default-route-openshift-image-registry.apps.$STACK_NAME.cp.fyre.ibm.com/$NAMESPACE/$IMAGE_NAME:$IMAGE_TAG --tls-verify=false
  # on cluster image: image-registry.openshift-image-registry.svc:5000/$NAMESPACE/$IMAGE_NAME:$IMAGE_TAG

  # remove the current zen-watchdog pod so that it will redeploy the new one
  oc delete cj -l icpdsupport/app=watchdog-cronjob
  oc delete rs -l component=zen-watchdog
  oc delete rs -n testns -l component=watchdog-service

  # now your new custom image is running!

  # go back to where you were
  cd -
}

function testapi() {
  # $WORKING_DIR/andrew-notes/test-api.sh
  python3 $WORKING_DIR/andrew-notes/test-api.py
}

function testapione() {
  $WORKING_DIR/andrew-notes/test-api-one.sh
}

function charging() {
  while [ $(system_profiler SPPowerDataType | grep "State of Charge" | awk '{print $5}') -lt 80 ]; do
    sleep 10
  done
  shortcuts run "Battery Charged"
}

function gfp() {
  git fetch -p
  git pull --all
  git branch -vv | grep ': gone]' | grep -v "\*" | awk '{ print $1; }' | xargs -r git branch -d
}
