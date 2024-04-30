#!/bin/bash

echo Build tomcat images with libxslt or xsltproc, CDI 2 and CXF support for 9 and above
LIST=$1
CDILIST=$2

if [ "$LIST" = "" ]; then
LIST="8.5-jdk8 8.5-jdk11 8.5-jdk8-temurin-focal 8.5-jdk8-slim 8.5-jdk8-openjdk-slim-bullseye 8.5-jdk8-corretto 8.5-jdk11-corretto 8.5-jdk11-openjdk-slim-bullseye 8.5-jdk11-temurin-focal 9-jdk11 9-jdk11-slim 9-jdk11-openjdk-slim 9-jdk11-corretto 9-jdk11-temurin-focal 9-jdk17-corretto 9-jdk17-temurin-focal 10.0-jdk11-temurin-focal 10.0-jdk11-corretto 10.0-jdk17-temurin-focal 10.0-jdk17-corretto"
fi

if [ "$CDILIST" = "" ]; then
CDILIST="no yes"
fi

if [ "$PUSH" = "yes" ]; then
PUSH_OPT="--push"
fi

if [ "$QUIET" != "" ]; then
QUIET_OPT="--quiet"
fi

#echo "Loading tomcat source from GitHub"
#
#docker run --rm -it -v tomcatwork:/root maven:3.8 bash -c "mkdir -p /root/tomcat-src && cd /root/tomcat-src && git clone https://github.com/apache/tomcat.git"

for t in $LIST
do

echo Building $t

if [[ "$t" == *"alpine" ]]; then
INSTALL_CMD='apk add --no-cache libxslt curl net-tools'
elif [[ "$t" == *"corretto" ]]; then
INSTALL_CMD='yum -y update && yum install -y libxslt net-tools && yum clean all'
else
INSTALL_CMD='apt-get update && apt-get -y upgrade && apt-get install -y xsltproc curl net-tools && rm -rf /var/lib/apt/lists/*'
fi

for cdi in $CDILIST; do
if [ "$cdi" == "yes" ]; then
MAVEN_TAG=3-eclipse-temurin-11
JD1=-Dmaven.compiler.source=11
JD2=-Dmaven.compiler.target=11
if [[ "$t" == "9"* ]]; then
	VER=9.0.x
  MAVEN_TAG=3.8-eclipse-temurin-8
  JD1=-Dmaven.compiler.source=1.8
  JD2=-Dmaven.compiler.target=1.8
elif [[ "$t" == "10.0"* ]]; then
	VER=10.0.x
elif [[ "$t" == "10.1"* ]]; then
	VER=10.1.x
fi
else
	VER=
fi

if [ "$VER" != "" ]; then

SRC_DIR=`pwd`/../tomcat-src/
mkdir -p $SRC_DIR

if [ ! -e "$SRC_DIR/tomcat" ]; then
docker run --rm -v $SRC_DIR:/opt/tomcat-src maven:$MAVEN_TAG sh -c "cd /opt/tomcat-src && git clone https://github.com/apache/tomcat.git"
fi

docker run --rm -v $SRC_DIR:/opt/tomcat-src -v m2cache:/root/.m2 maven:$MAVEN_TAG sh -c "cd /opt/tomcat-src/tomcat && git reset --hard && git checkout $VER && sed -i 's/<release>1.8<\/release>//' modules/owb/pom.xml && mvn $JD1 $JD2 clean install -f modules/owb && mvn $JD1 $JD2 clean install -f modules/cxf"

mkdir -p build && mv $SRC_DIR/tomcat/modules/owb/target/tomcat-owb-*.jar $SRC_DIR/tomcat/modules/cxf/target/tomcat-cxf-*.jar build/

docker run --rm -v $SRC_DIR:/opt/tomcat-src -v m2cache:/root/.m2 maven:$MAVEN_TAG sh -c "cd /opt/tomcat-src/tomcat && mvn clean -f modules/owb && mvn clean -f modules/cxf"

COPY_CDI_FILES="COPY "`ls build/tomcat-owb-*.jar`" /usr/local/tomcat/lib/"
ADD_CDI_SCRIPT="ADD xsl/server-cdi.xsl /usr/local/tomcat/"
COPY_CXF_FILES="COPY "`ls build/tomcat-cxf-*.jar`" /usr/local/tomcat/lib/"
fi

envsubst > Dockerfile <<EOF
FROM tomcat:$t
LABEL maintainer="thachanh@esi.vn"

RUN $INSTALL_CMD

$COPY_CDI_FILES
$COPY_CXF_FILES

ADD scripts/catalina-run.sh /usr/local/tomcat/bin
ADD xsl/context-ldap-realm.xsl /usr/local/tomcat/
ADD xsl/server-ldap-realm.xsl /usr/local/tomcat/
ADD xsl/context-db-realm.xsl /usr/local/tomcat/
ADD xsl/server-db-realm.xsl /usr/local/tomcat/
ADD xsl/context-dbsource.xsl /usr/local/tomcat/
ADD xsl/server-dbsource.xsl /usr/local/tomcat/
ADD xsl/server-cluster.xsl /usr/local/tomcat/
ADD xsl/server-port.xsl /usr/local/tomcat/
$ADD_CDI_SCRIPT

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

#Yes or empty
ENV GLOBAL_REALM=
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

ENV CDI_ENABLE=

ENV TOMCAT_HTTP_PORT=
ENV TOMCAT_HTTPS_PORT=
ENV TOMCAT_AJP_PORT=
ENV CONNECTOR_MAX_THREADS=

CMD ["catalina-run.sh"]

EOF

TAG=$t
if [ "$VER" != "" ]; then
	ALT=-cdi
else
	ALT=
fi

IMAGE_TAG="${MY_DOCKER_REGISTRY}tomcat-xslt$ALT:$TAG"

if [ "$REGISTRY_URL" != "" ]; then
IMAGE_TAG1="$REGISTRY_URL/tomcat-xslt$ALT:$TAG"
fi
if [ "$REGISTRY_URL2" != "" ]; then
IMAGE_TAG2="$REGISTRY_URL2/tomcat-xslt$ALT:$TAG"
fi

if [ "$IMAGE_TAG2" != "" ]; then
        docker buildx build $QUIET_OPT $PUSH_OPT --platform ${BUILD_PLATFORM:-local} -t "$IMAGE_TAG2" -t "$IMAGE_TAG1" -t "$IMAGE_TAG" .
elif [ "$IMAGE_TAG1" != "" ]; then
        docker buildx build $QUIET_OPT $PUSH_OPT --platform ${BUILD_PLATFORM:-local} -t "$IMAGE_TAG1" -t "$IMAGE_TAG" .
else
	docker build -t "$IMAGE_TAG" .
	[ "$PUSH" = "yes" ] && docker push "$IMAGE_TAG"
fi
done
done

rm -f Dockerfile
