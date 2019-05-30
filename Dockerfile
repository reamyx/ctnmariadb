#官方centos7镜像初始化,镜像TAG: ctnmariadb

FROM        imginit
LABEL       function="ctnmariadb"

#添加本地资源
ADD     mariadb     /srv/mariadb/

WORKDIR /srv/mariadb

#功能软件包
RUN     set -x \
        && cd ../imginit \
        \
        && yum -y install mariadb mariadb-server \
        \
        && yum clean all \
        && rm -rf /tmp/* \
        && cat ../mariadb/my-clt.cnf > /etc/my.cnf \
        && find ../ -name "*.sh" -exec chmod +x {} \;

ENV       ZXDK_THIS_IMG_NAME    "ctnmariadb"
ENV       SRVNAME               "mariadb"

# ENTRYPOINT CMD
CMD [ "../imginit/initstart.sh" ]
