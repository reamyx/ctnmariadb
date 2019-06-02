#!/bin/env sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"; cd "$(dirname "$0")"
exec 4>&1; ECHO(){ echo "${@}" >&4; }; exec 3<>"/dev/null"; exec 0<&3;exec 1>&3;exec 2>&3

SRVNM="mysqld-mariadb"

#先行服务停止
for ID in {1..30}; do pkill -f "$SRVNM" || break; sleep "0.5"; done
pidof "$SRVNM" && exit 2; [ "$1" == "stop" ] && exit 0

#DDNS注册
DDNSREG="./PeriodicRT-ddns-update"
[ -f "$DDNSREG" ] && ( chmod +x "$DDNSREG"; setsid "$DDNSREG" & )

DATALIB="./datalib"
DBINIT="$DATALIB/DataBase.Initializtioned"

#环境变量未能提供配置数据时从配置文件读取
[ -z "$SRVCFG" ] && SRVCFG="$( jq -scM ".[0]|objects" "./workcfg.json" )"

#提取服务配置参数(端口,授权配置,root密码等)
ROOTPWD="$( echo "$SRVCFG" | jq -r ".mariadb.rootpwd|strings" )"
SRVPORT="$( echo "$SRVCFG" | jq -r ".mariadb.srvport|numbers" )"
DBAUTHZ="$( echo "$SRVCFG" | jq -r ".mariadb.dbauthz|arrays" )"

#提取端口和root密码
ROOTPWD="${ROOTPWD:-abc000}"
SRVPORT="${SRVPORT:-3306}"

#服务环境初始化
mkdir -p "$DATALIB"
echo "\
[mysqld]
user=mysql
bind-address=0.0.0.0
datadir=$DATALIB
port=$SRVPORT
basedir=/usr
tmpdir=/tmp
plugin-dir=/usr/lib64/mysql/plugin
socket=/var/lib/mysql/mysql.sock
log_error=./mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
symbolic-links=0
init_connect='SET collation_connection = utf8_unicode_ci' 
init_connect='SET NAMES utf8'
character-set-server=utf8
collation-server=utf8_unicode_ci 
skip-character-set-client-handshake
innodb_buffer_pool_size=50M
" > ./mariadb.cnf

#若首次启动则初始化数据库
[ -f "$DBINIT" ] || mysql_install_db --defaults-file="./mariadb.cnf"

#检测到数据库服务就绪时尝试配置root账户密码并添加远程访问授权
((  [ -r "$DBINIT" ] && {
        read -t 1 ROOTPWD <"$DBINIT"; ROOTPWD="$( echo "$ROOTPWD" | base64 -d )"; }
    for ID in {1..30}; do sleep 0.5
        mysqladmin -u"root" password "$ROOTPWD"
        mysqladmin ping -u"root" -p"$ROOTPWD" && break; done
    [ -f "$DBINIT" ] || {
        echo -n "$ROOTPWD" | base64 > "$DBINIT"
        mysql -u"root" -p"$ROOTPWD" -e "DROP DATABASE test;"; }
    AUNO="$( echo "$DBAUTHZ" | jq -rcM "length" )"
    for((ID=0;ID<AUNO;ID++)); do
        AUNM="$( echo "$DBAUTHZ" | jq -rcM ".[$ID]|objects.usernm|strings" )"
        AUPW="$( echo "$DBAUTHZ" | jq -rcM ".[$ID]|objects.passwd|strings" )"
        AUDB="$( echo "$DBAUTHZ" | jq -rcM ".[$ID]|objects.dbname|strings" )"
        [[ -z "$AUNM" || -z "$AUPW" ]] && continue; AUDB="${AUDB:-*}"
        mysql -u"root" -p"$ROOTPWD" -e "GRANT ALL PRIVILEGES ON $AUDB.* TO
        '$AUNM'@'%' IDENTIFIED BY '$AUPW'; GRANT ALL PRIVILEGES ON $AUDB.*
        TO '$AUNM'@'localhost' IDENTIFIED BY '$AUPW'; FLUSH PRIVILEGES;"
        done ) & cd / )

#启动mariadb服务
exec -a "$SRVNM" /usr/libexec/mysqld --defaults-file="./mariadb.cnf"

exit 0
