# заменить хостовый nginx сервер контейнерным

На хосте действует хост-nginx-вебсервер. 
Задача: 
1. развернуть на этом хосте резервирующий nginx-вебсервер, 
2. назначить его действующим веб-сервером, а
3. хост-nginx-вебсервер перевести в резерв.

## Останавить хост-nginx-вебсервер

```bash
# остановить хостовый nginx сервер
$ sudo service nginx stop
```
## Скачать образ docker-nginx-вебсервер из репозитория

```bash
# img-ы контейнеров в локальном docker хранилище
$ sudo docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         1.25.3    a6bd71f48f68   3 weeks ago    187MB
```
## Перенастроить конфигурационный файл хост-nginx-вебсервера

Изменить конфигурационный файл хост-nginx-сервера для управления nginx-вебсервером в контейнере:
```
# конфигурационный файл хост-nginx-вебсервера в домашней папке
# ~/etc/nginx/nginx.conf
# это копия файла /etc/nginx/nginx.conf хост-nginx-вебсервера
#
#user administrator;     # имя пользователя хостового nginx  

user nginx;     # имя пользователя здесь установлено равным
                # имени пользователя 
	        # в установочном /etc/nginx/nginx.conf
                # образа из репозитория docker hub

worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
}

http {

        # Logging Settings
        ##
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        # для кирилических знаков
        charset UTF-8;
        upstream backend {
            server 192.168.1.118;      # www сервер
            server 192.168.1.68:8090;  # Database сервер
            server 192.168.1.118:8090; # www2 сервер
        }
        server {
                location / {
                        proxy_pass http://backend;
                }
        }
}
```

## Запустить nginx-вебсервер в контейнере

```bash
# создание и запуск контейнера с nginx сервером
#
# в контейнер импортирутся (пробрасываетя) конфигурационный
# файл, приведенный выше
$ sudo docker run -d --name nginx1 -p 80:80 -v /home/administrator/etc/nginx/nginx.conf:/etc/nginx/nginx.conf nginx:1.25.3

```

## Наблюдать tcp службы хост сервера

```bash
# наблюдение работы сервера nginx в контейнере
#
$ sudo docker ps
...
7810fd966414   nginx:1.25.3   "/docker-entrypoint.…"   26 minutes ago   Up 26 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp   nginx1

$ sudo ss -ntlp
State           Recv-Q          Send-Q                     Local Address:Port                      Peer Address:Port          Process
LISTEN          0               4096                             0.0.0.0:80                             0.0.0.0:*              users:(("docker-proxy",pid=35926,fd=4))
...

```

## Наблюдать действие docker-nginx-вебсервера

```bash
# наблюдение работы балансировочного действия
# сервера nginx
#
$ curl -s localhost | grep title | sed -e 's/^\s*//g'
<title>www2 server</title>
$ curl -s localhost | grep title | sed -e 's/^\s*//g'
<title>www server</title>
$ curl -s localhost | grep title | sed -e 's/^\s*//g'
<title>Database Error</title>
$ curl -s localhost | grep title | sed -e 's/^\s*//g'
<title>www2 server</title>

```
