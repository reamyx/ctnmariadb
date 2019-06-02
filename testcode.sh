#!/bin/env sh
exit 0

#数据库: mrdb198 状态容器
SRVCFG='{"initdelay":2,"workstart":"./mariadbstart.sh",
"workwatch":15,"workintvl":5,"firewall":{"tcpportpmt":"3306","icmppermit":"yes"},
"mariadb":{"dbauthz":[
{"usernm":"pbradmin","passwd":"pbrpw000","dbname":"pbrlogdb"},
{"usernm":"proxyadmin","passwd":"proxypw000","dbname":"proxylogdb"}]}}'; \
docker stop mrdb198; docker rm mrdb198; \
docker container run --detach --restart always \
--name mrdb198 --hostname mrdb198 \
--network imvn --cap-add NET_ADMIN \
--volume /etc/localtime:/etc/localtime:ro \
--volume /srv/datadisk:/srv/mariadb/datalib \
--ip 192.168.15.198 --dns 192.168.15.192 --dns-search local \
--env "SRVCFG=$SRVCFG" ctnmariadb

docker container exec -it mrdb198 bash
