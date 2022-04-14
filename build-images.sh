#!/bin/sh

echo Build tomcat images with libxslt or xsltproc

#my registry: REGISTRY_URL=registry.esi.vn:5000 REGISTRY_USER=gitlab REGISTRY_PASSWORD=Demoesi2021

if [ "$REGISTRY_URL" != "" ]
then
        docker login -u "$REGISTRY_USER" -p "$REGISTRY_PASSWORD" "$REGISTRY_URL"
fi

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

if [ "$REGISTRY_URL" != "" ]; then
        docker logout $REGISTRY_URL
fi

