# Домашнее задание №3 - Hive

На edge (`team-08-en`) устанавливаем HiveServer2, отдельный Hive Metastore и PostgreSQL для метаданных. Клиенты подключаются к HiveServer2 через Beeline или JDBC и могут работать одновременно. Данные храним в HDFS, запросы выполняем через MapReduce на YARN из [ДЗ №2](../hw-2).

Выбрали Hive 4.1.0 для Java 17 из предыдущих заданий. В задании рекомендован 4.0.0-alpha-2; поддержку Java 17 добавили в 4.1.0. [Требования Apache Hive](https://hive.apache.org/general/downloads/).

Через `hive.aux.jars.path` передаём задачам MapReduce библиотеку `commons-collections-3.2.2.jar` из Hive: она нужна Hive, но в Hadoop 3.4.2 её нет.

## Запуск

Нужны работающие ДЗ №1 и №2, Ubuntu 24.04 amd64 на edge, SSH-доступ к `team@2.59.83.169` и `sudo` без пароля у `team`. На edge должен быть ключ `~/.ssh/team_internal` для доступа к остальным узлам, как в ДЗ №2. Hadoop 3.4.2 должен стоять в `/opt/hadoop`, конфиги - в `/etc/hadoop`. Для PostgreSQL нужен свободный порт 5432 или стандартная установка PostgreSQL Ubuntu с доступом через `sudo -u postgres`.

Из корня репозитория:

```bash
bash hw-3/deploy.sh
```

Скрипт копирует файлы в `~/hw3-hive` на edge, скачивает Hive с проверкой SHA-256, устанавливает PostgreSQL и JDBC-драйвер. Затем настраивает службы systemd, загружает данные и запускает проверку.

Перед установкой `hosts-setup.sh` прописывает короткие и полные имена четырёх узлов в `/etc/hosts` с адресами от `10.8.0.10` до `10.8.0.13`. Иначе ApplicationMaster может передать задачам адрес `127.0.1.1`, недоступный с других машин. Исходный файл сохраняем в `/etc/hosts.before-hw3`.

Пароль PostgreSQL хранится на edge в `/etc/hive/metastore-password` и `/etc/hive/hivemetastore-site.xml`, доступных root и группе `hadoop`. При повторном запуске сохраняем пароль и схему metastore, заменяем конфиги, перезапускаем службы и загружаем учебные данные заново. Перед этим завершите активные запросы.

## Загрузка данных

В `data/` лежат два CSV без заголовка с полями `event_id`, `user_id`, `event_type`. В `sql/load.sql` создаём внешнюю таблицу `hw3.events` с партицией `dt` и загружаем по три события за `2026-10-01` и `2026-10-02`.

`load-data.sh` копирует CSV в `/var/lib/hive/import` на edge, откуда `LOAD DATA LOCAL` загружает их в HDFS. Данные таблицы лежат в `/user/hive/external/hw3/events/dt=...`.

Повторить загрузку:

```bash
ssh team@2.59.83.169 'bash ~/hw3-hive/load-data.sh'
```

Через `OVERWRITE` заменяем содержимое двух учебных партиций, поэтому после повторной загрузки остаются те же шесть строк. Запускайте одну загрузку за раз.

## Подключение

На edge:

```bash
ssh team@2.59.83.169
source ~/hw3-hive/common.sh
"${BEELINE[@]}"
```

Повторите команды во втором терминале для подключения ещё одного клиента.

Для JDBC-клиента на своём компьютере откройте SSH-туннель:

```bash
bash hw-3/deploy.sh --tunnel
```

Подключайтесь к `jdbc:hive2://127.0.0.1:10000/default` с пользователем `hadoop` без пароля. Оставьте терминал с туннелем открытым.

HiveServer2 и metastore слушают localhost, доступ снаружи идёт через SSH. В этой учебной установке все клиенты выполняют запросы от `hadoop`, разделения прав между ними нет.

## Проверка

```bash
ssh team@2.59.83.169 'bash ~/hw3-hive/check.sh'
```

Проверяем службы, схему metastore, две партиции и все шесть строк по `data/expected.tsv`. Затем открываем две сессии и читаем из них данные.

В Beeline можно проверить вручную:

```sql
SHOW PARTITIONS hw3.events;
SELECT dt, COUNT(*) FROM hw3.events GROUP BY dt ORDER BY dt;
```

Должны получиться две даты и по три строки на каждую. После повторного запуска `load-data.sh` результат тот же.

Журналы служб на edge:

```bash
sudo journalctl -u hive-metastore -u hive-server2 -n 100 --no-pager
```
