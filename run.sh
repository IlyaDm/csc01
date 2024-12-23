#!/bin/bash

# 1. Проверяем наличие Docker и устанавливаем, если его нет
if ! command -v docker &> /dev/null; then
  echo "Docker не установлен. Устанавливаем Docker..."
  sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  echo "Docker успешно установлен."
else
  echo "Docker уже установлен."
fi

# 2. Проверяем наличие файла с адресами
if [ ! -f addresses.txt ]; then
  echo "Файл addresses.txt не найден. Пожалуйста, создайте файл с адресами построчно."
  exit 1
fi

# 3. Считываем адреса из файла
addresses=()
while IFS= read -r line || [[ -n "$line" ]]; do
  addresses+=("$line")
done < addresses.txt

# Проверяем количество адресов
if [ ${#addresses[@]} -lt 1 ]; then
  echo "Файл addresses.txt пуст. Укажите адреса построчно."
  exit 1
fi

echo "Найдено ${#addresses[@]} адресов. Будет запущено соответствующее количество нод."

# 4. Создаём или перезапускаем контейнеры
for i in "${!addresses[@]}"; do
  container_name="cysic-$((i+1))"
  host_port=$((8000 + i + 1)) # Порты: 8001, 8002, 8003, ...

  # Если контейнер уже существует, пропускаем его создание
  if docker ps -a | grep -q "$container_name"; then
    echo "Контейнер $container_name уже существует. Пропускаем создание."
    docker start "$container_name" > /dev/null 2>&1 || echo "Контейнер $container_name уже запущен."
  else
    # Создаём новый контейнер
    echo "Создаём и запускаем контейнер $container_name с адресом ${addresses[$i]} на порту $host_port..."
    docker run -d \
      --name "$container_name" \
      -v "$(pwd)/data/node$((i+1)):/root/.cysic" \
      -p "$host_port:80" \
      --env CLAIM_REWARD_ADDRESS="${addresses[$i]}" \
      cysic-node
  fi
done

# 5. Удаляем лишние контейнеры, если их больше, чем адресов
existing_containers=$(docker ps -a --format "{{.Names}}" | grep -E '^cysic-[0-9]+$')
for container in $existing_containers; do
  container_index=$(echo "$container" | grep -oE '[0-9]+$')
  if [ "$container_index" -gt "${#addresses[@]}" ]; then
    echo "Останавливаем и удаляем контейнер $container, так как он больше не нужен."
    docker rm -f "$container"
  fi
done

# 6. Вывод информации о запущенных контейнерах
echo "Контейнеры запущены:"
docker ps | grep cysic-
