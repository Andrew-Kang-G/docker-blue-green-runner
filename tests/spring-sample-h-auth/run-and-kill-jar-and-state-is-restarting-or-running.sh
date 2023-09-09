#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -eu

cd ../../

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

container=$(echo "$(docker ps --format '{{.Names}}' | grep "spring-sample-h-auth")")
if [ -z "$container" ]; then
  echo "[NOTICE] There is NO spring-sample-h-auth container, now we will build it."
  cp -f .env.java.real .env
  echo "$(pwd)"
  sudo bash run.sh
else
  echo "[NOTICE] $container exists."
fi

sleep 3
source ./util.sh

cache_global_vars

consul_pointing=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw 2>/dev/null || echo "failed")

echo "[TEST][NOTICE] ! Kill the jar in ${project_name}-${consul_pointing}"
docker exec ${project_name}-${consul_pointing} bash -c "kill 9 7"

# Print state checking process
result=$(cache_all_states)

# 결과가 "AAA"를 포함하는 경우 "SUCCESS"를 출력합니다.
if [[ $result == *"currently running"* || $result == *"currently restarting"* ]]; then
    echo "SUCCESS"
else
  echo "FAILURE"
fi