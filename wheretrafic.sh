#!/bin/bash

while [ "1" -lt "2" ]
do
  sleep 1
  #echo "Hello"

  # генерация трафика на порт 1314
  curl -s localhost:1314 | grep -P '<title.+Welcome' > nul

  # вывод статиски трафика трех контейнов
  # цель - увидеть контейнер, через который идет генерируемый трафик
  ./trafic.sh
done
