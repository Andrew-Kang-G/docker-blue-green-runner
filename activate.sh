#!/usr/bin/env bash
set -e
sudo sed -i -e "s/\r$//g" $(basename $0)

source ./util.sh

cache_global_vars

new_state=$1
old_state=$2
new_upstream=$3
consul_key_value_store=$4

echo "[NOTICE] new_state : ${new_state}, old_state : ${old_state}, new_upstream : ${new_upstream}, consul_key_value_store : ${consul_key_value_store}"
was_state=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw)
echo "[NOTICE] CONSUL (${consul_key_value_store}) is pointing to : ${was_state}"

# ${pid_was} != '-' 의 의미는 Nginx 가 완전히 띄어졌을 때 CONSUL 에 BLUE-GREEN 변경 작업을 진행한다는 의미이다.
echo "[NOTICE] Check if Nginx is completely UP."
for retry_count in {1..5}; do
  pid_was=$(docker exec ${project_name}-nginx pidof nginx 2>/dev/null || echo '-')

  if [[ ${pid_was} != '-' ]]; then
    echo "[NOTICE] Nginx is completely UP."
    break
  else
    echo "[NOTICE] Retrying... (pid_was : ${pid_was})"

  fi

  if [[ ${retry_count} -eq 4 ]]; then
    echo "[ERROR] Failed to verify if Nginx is completely up and running. Retry attempt also failed. The script will now maintain the existing state and terminate."
    exit 1
  fi

  echo "[NOTICE] Retrying every 3 seconds... (Retrying ${retry_count} round)"
  sleep 3
done

echo "[NOTICE] Activate ${new_state} CONSUL. (old Nginx pids: ${pid_was})"
echo "[NOTICE] ${new_state} is stored in CONSUL."
docker exec ${project_name}-nginx curl -X PUT -d ${new_state} ${consul_key_value_store} >/dev/null

sleep 1

echo "[NOTICE] The PID of NGINX has been confirmed. Now, checking if CONSUL has been replaced with ${new_upstream} string in the NGINX configuration file."
count=0
while [ 1 ]; do
  lines=$(docker exec ${project_name}-nginx nginx -T | grep ${new_state} | wc -l | xargs)
  if [[ ${lines} == '0' ]]; then
    count=$((count + 1))
    if [[ ${count} -eq 10 ]]; then
      echo "[WARNING] Since ${new_upstream} string is not found in the NGINX configuration file, we will revert CONSUL to ${old_state} (although it should already be ${old_state}, we will save it again to ensure)"
        ./reset.sh ${consul_key_value_store} ${old_state} ${new_state}
      exit 1
    fi
    echo 'Wait for the new configuration'
    sleep 3
  else
    echo 'The new configuration was loaded'
    break
  fi
done
