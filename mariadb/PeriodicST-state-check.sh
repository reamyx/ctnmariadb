#!/bin/env sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

#服务状态测试
pidof "mysqld-mariadb" > "/dev/null"
