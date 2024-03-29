#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -eu

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh
source ./use-nginx.sh


check_necessary_commands
cache_global_vars
check_env_integrity

# Eventually, it will be activated as 'state_a' in ./activate.sh, and unless specifically specified parameters as below,
# Nginx should be reconfigured with the existing state (from 'cache_global_vars').
state_a=${state_for_emergency}
state_b=${state_for_emergency}
if [[ ! -z ${1:-} ]] && ([[ ${1} == "blue" ]] || [[ ${1} == "green" ]]); then
    echo "[DEBUG] state_a : ${1}"
    state_a=${1}
fi

if [[ ${protocol} = 'https' ]]; then
  state_upstream=$(concat_safe_port "https://${project_name}-${state_a}")
else
  state_upstream=$(concat_safe_port "http://${project_name}-${state_a}")
fi


echo "[NOTICE] Finally, !! Deploy the App as !! ${state_a} !!, we will now deploy '${project_name}' in a way of 'Blue-Green'"
# run
nginx_down_and_up
# activate : blue or green
./activate.sh ${state_a} ${state_b} ${state_upstream} ${consul_key_value_store}