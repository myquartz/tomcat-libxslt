#!/bin/bash

echo Build tomcat images with libxslt or xsltproc, CDI 2 and CXF support for 9 and above
LIST=$1
CDILIST=$2

if [ "$LIST" = "" ]; then
LIST="8.5-jdk8 8.5-jdk8-temurin 8.5-jdk8-temurin-focal 8.5-jdk8-temurin-jammy 8.5-jdk8-corretto 8.5-jdk8-corretto-al2 8.5-jdk11 8.5-jdk11-temurin 8.5-jdk11-temurin-jammy 8.5-jdk11-temurin-focal 8.5-jdk11-corretto 8.5-jdk11-corretto-al2 9-jdk11 9-jdk11-temurin 9-jdk11-temurin-jammy 9-jdk11-temurin-focal 9-jdk11-temurin-noble 9-jdk11-corretto 9-jdk11-corretto-al2 9-jdk17 9-jdk17-temurin 9-jdk17-temurin-jammy 9-jdk17-temurin-focal 9-jdk17-temurin-noble 9-jdk17-corretto 9-jdk17-corretto-al2 10-jdk11 10-jdk11-temurin 10-jdk11-temurin-jammy 10-jdk11-temurin-focal 10-jdk11-temurin-noble 10-jdk11-corretto 10-jdk11-corretto-al2 10-jdk17 10-jdk17-temurin 10-jdk17-temurin-jammy 10-jdk17-temurin-focal 10-jdk17-temurin-noble 10-jdk21-temurin-noble 10.1-jdk17 10.1-jdk17-temurin 10.1-jdk17-temurin-jammy 10.1-jdk17-temurin-noble 10.1-jdk21-temurin-noble 11.0-jdk21-temurin-noble"
fi

if [ "$CDILIST" = "" ]; then
CDILIST="no yes"
fi

if [ "$PUSH" = "yes" ]; then
PUSH_OPT="--push"
fi

if [ "$QUIET" != "" ]; then
BUILDER_OPT="$BUILDER_OPT --quiet"
fi

if [ -r "./profile.conf" ]; then
        source ./profile.conf
        export REGISTRY_URL USING_BUILDX MY_DOCKER_REGISTRY BUILD_PLATFORM TAG_POSTFIX LATEST_TAG
fi

#echo "Loading tomcat source from GitHub"
#
#docker run --rm -it -v tomcatwork:/root maven:3.8 bash -c "mkdir -p /root/tomcat-src && cd /root/tomcat-src && git clone https://github.com/apache/tomcat.git"

for cdi in $CDILIST; do
for t in $LIST
do

echo Building $t cdi=$cdi

if [[ "$t" == *"alpine" ]]; then
INSTALL_CMD='apk add --no-cache libxslt curl'
elif [[ "$t" == *"corretto"* ]]; then
INSTALL_CMD='yum -q -y update && yum install -q -y libxslt && yum clean all'
else
INSTALL_CMD='apt-get -q update && apt-get -q -y upgrade && apt-get -q install -y xsltproc curl && rm -rf /var/lib/apt/lists/*'
fi

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
elif [[ "$t" == "11.0"* ]]; then
	MAVEN_TAG=3-eclipse-temurin-17
  JD1=-Dmaven.compiler.source=17
  JD2=-Dmaven.compiler.target=17
	VER=11.0.x
fi
else
	VER=
fi

if [ "$VER" != "" ]; then

OUT_DIR=`pwd`/build
mkdir -p $OUT_DIR

docker run --rm -v tomcat-src:/opt/tomcat-src maven:$MAVEN_TAG sh -c "cd /opt/tomcat-src && [ ! -e tomcat ] && git clone https://github.com/apache/tomcat.git"

echo "Running build for $VER"

docker run --rm -i -v tomcat-src:/opt/tomcat-src -v m2cache:/root/.m2 maven:$MAVEN_TAG sh -c \
	"cd /opt/tomcat-src/tomcat && [ ! -e /opt/tomcat-src/$VER ] && git reset --hard && git checkout $VER && sed -i 's/<release>1.8<\/release>//' modules/owb/pom.xml && mvn $JD1 $JD2 clean install -q -f modules/owb && sed -i 's/<version>3.5.3/<version>3.5.5/' modules/cxf/pom.xml && mvn $JD1 $JD2 clean install -q -f modules/cxf && tar -vcf /opt/tomcat-src/$VER modules/owb/target/tomcat-owb-*.jar modules/cxf/target/tomcat-cxf-*.jar"

docker run -d --rm --name cp-$VER -v tomcat-src:/opt/tomcat-src maven:$MAVEN_TAG sh -c "sleep 20"

docker cp cp-$VER:/opt/tomcat-src/$VER $OUT_DIR/$VER.tar && mkdir -p $OUT_DIR/$VER && tar -C $OUT_DIR/$VER -vxf $OUT_DIR/$VER.tar

ADD_CDI_SCRIPT="ADD xsl/server-cdi.xsl /usr/local/tomcat/"
COPY_CDI_FILES="COPY "`ls build/$VER/modules/owb/target/tomcat-owb-*.jar | xargs echo -n`" /usr/local/tomcat/lib/"
COPY_CXF_FILES="COPY "`ls build/$VER/modules/cxf/target/tomcat-cxf-*.jar | xargs echo -n`" /usr/local/tomcat/lib/"
else

COPY_CDI_FILES=
ADD_CDI_SCRIPT=
COPY_CXF_FILES=
fi

envsubst > Dockerfile <<EOF
FROM tomcat:$t
LABEL maintainer="myquartz@gmail.com"

RUN $INSTALL_CMD

$COPY_CDI_FILES
$COPY_CXF_FILES

ADD scripts/catalina-xslt.sh /usr/local/tomcat/bin
ADD xsl/context-any-resource.xsl /usr/local/tomcat/
ADD xsl/context-environment.xsl /usr/local/tomcat/
ADD xsl/context-parameter.xsl /usr/local/tomcat/
ADD xsl/context-ldap-realm.xsl /usr/local/tomcat/
ADD xsl/server-ldap-realm.xsl /usr/local/tomcat/
ADD xsl/context-db-realm.xsl /usr/local/tomcat/
ADD xsl/server-db-realm.xsl /usr/local/tomcat/
ADD xsl/context-dbsource.xsl /usr/local/tomcat/
ADD xsl/server-dbsource.xsl /usr/local/tomcat/
ADD xsl/server-cluster.xsl /usr/local/tomcat/
ADD xsl/server-port.xsl /usr/local/tomcat/

$ADD_CDI_SCRIPT

RUN cp /usr/local/tomcat/conf/server.xml /usr/local/tomcat/server-orig.xml && chmod +x /usr/local/tomcat/bin/catalina-xslt.sh

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

CMD ["catalina-xslt.sh", "run"]

EOF

TAG=$t
if [ "$VER" != "" -a "$cdi" = "yes" ]; then
	ALT=-cdi
elif [ "$cdi" = "yes" ]; then
	echo "ignore $t, no support CDI"
	continue
else
	ALT=
fi

IMAGE_TAG="${MY_DOCKER_REGISTRY}tomcat-xslt$ALT:$TAG"

if [ "$t" = "$LATEST_TAG" ]; then 
LATEST_OPT1="-t ${MY_DOCKER_REGISTRY}tomcat-xslt$ALT:latest$TAG_POSTFIX"
else
LATEST_OPT1=
fi

if [ "$REGISTRY_URL" != "" ]; then
  IMAGE_TAG1="$REGISTRY_URL/tomcat-xslt$ALT:$TAG"
	if [ "$t" = "$LATEST_TAG" ]; then 
		LATEST_OPT2="-t $REGISTRY_URL/tomcat-xslt$ALT:latest$TAG_POSTFIX"
  else
		LATEST_OPT2=
	fi
fi

if [ "$IMAGE_TAG1" != "" ]; then
  docker buildx build $BUILDER_OPT $PUSH_OPT --platform ${BUILD_PLATFORM:-local} $LATEST_OPT1 $LATEST_OPT2 -t "$IMAGE_TAG1" -t "$IMAGE_TAG" .
elif [ "$USING_BUILDX" != "" ]; then
	docker buildx build $BUILDER_OPT $PUSH_OPT --platform ${BUILD_PLATFORM:-local} $LATEST_OPT1 $LATEST_OPT2 -t "$IMAGE_TAG" .
else
	docker build -q -t "${IMAGE_TAG}${TAG_POSTFIX}" $LATEST_OPT1 $LATEST_OPT2 .
	if [ "$PUSH" = "yes" ]; then
 		docker push -q "${IMAGE_TAG}${TAG_POSTFIX}"
		[ "$LATEST_OPT1" != "" ] && docker push -q $LATEST_OPT1
		[ "$LATEST_OPT2" != "" ] && docker push -q $LATEST_OPT2
	fi
fi

done
done

#rm -fR build
rm -f Dockerfile
