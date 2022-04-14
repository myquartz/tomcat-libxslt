#!/bin/sh

echo Build tomcat images with libxslt or xsltproc

for t in 8.5-jdk8 8.5-jdk11 8.5-jdk8-slim 8.5-jdk8-openjdk-slim-bullseye 8.5-jdk8-corretto 8.5-jdk11-corretto 8.5-jdk11-openjdk-slim-bullseye 9-jdk11 9-jdk11-slim 9-jdk11-openjdk-slim 9-jdk11-openjdk-slim-bullseye 9-jdk11-corretto
do

echo Building $t

IMAGE_TAG="tomcat-xslt:$t"

if [ "$REGISTRY_URL" != "" ]; then
IMAGE_TAG1="$REGISTRY_URL/tomcat-xslt:$t"
fi
if [ "$PRIV_REGISTRY" != "" ]; then
IMAGE_TAG2="$PRIV_REGISTRY/tomcat-xslt:$t"
fi

if [[ "$t" == *"alpine" ]]; then
INSTALL_CMD='apk add --no-cache libxslt curl'
elif [[ "$t" == *"corretto" ]]; then
INSTALL_CMD='yum -y update && yum install -y libxslt && yum clean all'
else
INSTALL_CMD='apt-get update && apt-get -y upgrade && apt-get install -y xsltproc curl && rm -rf /var/lib/apt/lists/*'
fi

envsubst > Dockerfile <<EOF
FROM tomcat:$t
LABEL maintainer="thachanh@esi.vn"

RUN $INSTALL_CMD

ADD scripts/catalina-run.sh /usr/local/tomcat/bin
ADD xsl/context-ldap-realm.xsl /usr/local/tomcat/
ADD xsl/server-ldap-realm.xsl /usr/local/tomcat/
ADD xsl/context-db-realm.xsl /usr/local/tomcat/
ADD xsl/server-db-realm.xsl /usr/local/tomcat/
ADD xsl/context-dbsource.xsl /usr/local/tomcat/
ADD xsl/server-dbsource.xsl /usr/local/tomcat/
ADD xsl/server-cluster.xsl /usr/local/tomcat/

RUN cp /usr/local/tomcat/conf/server.xml /usr/local/tomcat/server-orig.xml && chmod +x /usr/local/tomcat/bin/catalina-run.sh

ENV DEPLOY_CONTEXT=

ENV GLOBAL_DB_SOURCENAME=
ENV DB_SOURCENAME=
ENV DB_CLASS=
ENV DB_URL=
ENV DB_USERNAME=
ENV DB_PASSWORD=

ENV GLOBAL_LDAP_URL=
ENV LDAP_URL=
ENV LDAP_BIND=
ENV LDAP_BIND_PASSWORD=
ENV LDAP_USER_BASEDN=
ENV LDAP_USER_SEARCH=
ENV LDAP_USER_PASSWD_ATTR=
ENV LDAP_USER_PATTERN=
ENV LDAP_GROUP_BASEDN=
ENV LDAP_GROUP_SEARCH=
ENV LDAP_GROUP_ATTR=

ENV REALM_USERTAB=
ENV REALM_ROLETAB=
ENV REALM_USERCOL=
ENV REALM_CREDCOL=
ENV REALM_ROLECOL=

ENV ALL_ROLES_MODE=

ENV CLUSTER=
ENV MCAST_ADDRESS=
ENV MCAST_PORT=
ENV RECEIVE_PORT=
ENV REPLICATION_FILTER=

CMD ["catalina-run.sh"]

EOF

if [ "$IMAGE_TAG1" != "" ]; then
        docker build --pull -t "$IMAGE_TAG" -t "$IMAGE_TAG1" .
        docker tag "$IMAGE_TAG" "$IMAGE_TAG1"
        docker push "$IMAGE_TAG1"
else
        docker build -t "$IMAGE_TAG" .
fi

if [ "$IMAGE_TAG2" != "" ]; then
        docker tag "$IMAGE_TAG" "$IMAGE_TAG2"
        docker push "$IMAGE_TAG2"
fi

done

rm -f Dockerfile
