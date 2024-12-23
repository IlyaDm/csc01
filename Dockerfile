FROM ubuntu:22.04

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    curl \
    bash \
    && apt-get clean

# Устанавливаем рабочую директорию
WORKDIR /root

# Скачиваем скрипт установки
RUN curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > setup_linux.sh

# Устанавливаем права на выполнение
RUN chmod +x setup_linux.sh

# Выполняем скрипт установки при запуске контейнера
CMD ["bash", "-c", "bash setup_linux.sh $CLAIM_REWARD_ADDRESS && cd /root/cysic-verifier && bash start.sh"]
