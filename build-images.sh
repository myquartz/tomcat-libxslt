#!/bin/sh

echo Build tomcat images with libxslt or xsltproc
LIST=$1

if [ "$LIST" = "" ]; then
LIST="8.5-jdk8 8.5-jdk11 8.5-jdk8-temurin-focal 8.5-jdk8-slim 8.5-jdk8-openjdk-slim-bullseye 8.5-jdk8-corretto 8.5-jdk11-corretto 8.5-jdk11-openjdk-slim-bullseye 8.5-jdk11-temurin-focal 9-jdk11 9-jdk11-slim 9-jdk11-openjdk-slim 9-jdk11-corretto 9-jdk11-temurin-focal 9-jdk17-corretto 9-jdk17-temurin-focal 10.0-jdk11-temurin-focal 10.0-jdk11-corretto 10.0-jdk17-temurin-focal 10.0-jdk17-corretto"
fi

if [ "$PUSH" = "yes" ]; then
PUSH_OPT="--push"
fi

for t in $LIST
do

echo Building $t

IMAGE_TAG="${MY_DOCKER_REGISTRY}tomcat-xslt:$t"

if [ "$REGISTRY_URL" != "" ]; then
IMAGE_TAG1="$REGISTRY_URL/tomcat-xslt:$t"
fi
if [ "$REGISTRY_URL2" != "" ]; then
IMAGE_TAG2="$REGISTRY_URL2/tomcat-xslt:$t"
fi

if [[ "$t" == *"alpine" ]]; then
INSTALL_CMD='apk add --no-cache libxslt curl net-tools'
elif [[ "$t" == *"corretto" ]]; then
INSTALL_CMD='yum -y update && yum install -y libxslt net-tools && yum clean all'
else
INSTALL_CMD='apt-get update && apt-get -y upgrade && apt-get install -y xsltproc curl net-tools && rm -rf /var/lib/apt/lists/*'
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
ADD xsl/server-port.xsl /usr/local/tomcat/

RUN cp /usr/local/tomcat/conf/server.xml /usr/local/tomcat/server-orig.xml && chmod +x /usr/local/tomcat/bin/catalina-run.sh

ENV DEPLOY_CONTEXT=

ENV GLOBAL_DB_SOURCENAME=
ENV DB_SOURCENAME=
ENV DB_CLASS=
ENV DB_URL=
ENV DB_USERNAME=
ENV DB_PASSWORD=
ENV DB_PASSWORD_FILE=

ENV GLOBAL_LDAP_URL=
ENV LDAP_URL=
ENV LDAP_BIND=
ENV LDAP_BIND_PASSWORD=
ENV LDAP_BIND_PASSWORD_FILE=
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
ENV CHANNEL_SEND_OPTIONS=

ENV TOMCAT_HTTP_PORT=
ENV TOMCAT_HTTPS_PORT=
ENV TOMCAT_AJP_PORT=
ENV CONNECTOR_MAX_THREADS=

CMD ["catalina-run.sh"]

EOF

if [ "$IMAGE_TAG2" != "" ]; then
        docker buildx build $PUSH_OPT --platform ${BUILD_PLATFORM:-local} -t "$IMAGE_TAG2" -t "$IMAGE_TAG1" -t "$IMAGE_TAG" .
elif [ "$IMAGE_TAG1" != "" ]; then
        docker buildx build $PUSH_OPT --platform ${BUILD_PLATFORM:-local} -t "$IMAGE_TAG1" -t "$IMAGE_TAG" .
else
	docker build -t "$IMAGE_TAG" .
	[ "$PUSH" = "yes" ] && docker push "$IMAGE_TAG"
fi
done

rm -f Dockerfile
