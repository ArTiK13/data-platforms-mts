# Домашнее задание №2 — YARN и внешние веб-интерфейсы

Скрипты добавляют YARN поверх HDFS из [ДЗ №1](../hw-1) и публикуют веб-интерфейсы через Nginx на edge и SSH-туннель к компьютеру пользователя.

## Узлы кластера

| Узел | Внутренний IP | Службы |
|---|---|---|
| `team-08-en` | `10.8.0.10` | DataNode, NodeManager, Nginx |
| `team-08-nn` | `10.8.0.11` | NameNode, SecondaryNameNode, ResourceManager, JobHistory Server |
| `team-08-00` | `10.8.0.12` | DataNode, NodeManager |
| `team-08-01` | `10.8.0.13` | DataNode, NodeManager |

## Предварительные условия

- На серверах установлены Ubuntu 24.04, Java 17, Python 3 и Hadoop 3.4.2 в `/opt/hadoop`
- Работают службы HDFS из ДЗ №1 и три DataNode
- У `team` есть `sudo` без пароля
- На edge есть ключ `~/.ssh/team_internal`, внутренние имена узлов разрешаются в IP из таблицы

## Запуск

Из корня репозитория:

```bash
bash hw-2/deploy.sh
```

Конфиги находятся в `config/hadoop`, `config/systemd` и `config/nginx`. Готовые `yarn-site.xml` и `mapred-site.xml` устанавливаются с заменой существующих файлов.

1. `deploy.sh` копирует файлы на edge в `~/hw2-yarn` и запускает `edge-deploy.sh`.
2. `node-setup.sh` на каждом узле настраивает Hadoop и устанавливает службы YARN и JobHistory.
3. `edge-deploy.sh` создаёт каталоги HDFS для задач, истории и агрегированных логов, затем запускает YARN и настраивает Nginx.
4. `check.sh` проверяет кластер и ожидает готовности YARN и JobHistory; `deploy.sh` проверяет все десять веб-интерфейсов на edge через SSH и открывает туннель.

Повторный запуск без `--web` перезапускает службы YARN и JobHistory, поэтому выполняйте его, когда нет пользовательских заданий.

## Веб-интерфейсы

Чтобы открыть интерфейсы без повторного развёртывания, на своём компьютере из корня репозитория запустите:

```bash
bash hw-2/deploy.sh --web
```

Оставьте терминал открытым, затем откройте ссылки из таблицы в браузере. Для остановки туннеля нажмите Ctrl+C. Используется SSH-доступ к `team@2.59.83.169` через порт 22.

| Интерфейс | URL через туннель |
|---|---|
| ResourceManager | http://127.0.0.1:8444/cluster |
| JobHistory Server | http://127.0.0.1:8445/jobhistory |
| NameNode | http://127.0.0.1:8446/dfshealth.html |
| SecondaryNameNode | http://127.0.0.1:8447/status.html |
| DataNode edge | http://127.0.0.1:8448/datanode.html |
| DataNode 0 | http://127.0.0.1:8449/datanode.html |
| DataNode 1 | http://127.0.0.1:8450/datanode.html |
| NodeManager edge | http://127.0.0.1:8451/node |
| NodeManager 0 | http://127.0.0.1:8452/node |
| NodeManager 1 | http://127.0.0.1:8453/node |

Для доступа через туннель нужен SSH-доступ к edge. Разрешены только GET/HEAD; изменение через UI закрыто, задачи отправляются из внутренней сети через CLI.

Ссылки внутри Hadoop могут вести на внутренние адреса.

## Проверка

После установки проверка запускается автоматически. Повторить её можно с локального компьютера:

```bash
ssh team@2.59.83.169 'bash ~/hw2-yarn/check.sh'
```

Скрипт проверяет службы и три живых DataNode, затем ожидает регистрации трёх NodeManager и готовности интерфейса JobHistory: до 30 попыток с паузой 3 секунды.

При открытом туннеле проверить ResourceManager со своего компьютера:

```bash
curl --noproxy '*' -I http://127.0.0.1:8444/cluster
```

Ожидается HTTP 200. При запуске `deploy.sh` этот статус проверяется на edge для всех интерфейсов из таблицы; в ResourceManager Nodes должны быть три работающих узла.
