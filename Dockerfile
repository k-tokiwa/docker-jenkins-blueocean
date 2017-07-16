FROM blacklabelops/jenkins-swarm
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

# Need root to build image
USER root

# install dev tools
RUN yum install -y \
    unzip && \
    yum clean all && rm -rf /var/cache/yum/*

# add repo && chromedriver
RUN yum -y install mesa-dri-drivers libexif libcanberra-gtk2 libcanberra; yum clean all

ADD https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm /root/google-chrome-stable_current_x86_64.rpm

RUN yum -y install /root/google-chrome-stable_current_x86_64.rpm; yum clean all
ADD chromedriver /usr/bin/
RUN chmod 755 /usr/bin/chromedriver

# this envs are for maintaining java updates.
ENV JAVA_MAJOR_VERSION=8
ENV JAVA_UPDATE_VERSION=102
ENV JAVA_BUILD_NUMER=14
# install java
ENV JAVA_VERSION=1.${JAVA_MAJOR_VERSION}.0_${JAVA_UPDATE_VERSION}
ENV JAVA_TARBALL=jdk-${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz
ENV JAVA_HOME=/opt/java/jdk${JAVA_VERSION}

RUN wget --directory-prefix=/tmp \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         http://download.oracle.com/otn-pub/java/jdk/${JAVA_MAJOR_VERSION}u${JAVA_UPDATE_VERSION}-b${JAVA_BUILD_NUMER}/${JAVA_TARBALL} && \
    mkdir -p /opt/java && \
    tar -xzf /tmp/${JAVA_TARBALL} -C /opt/java/ && \
    alternatives --remove java ${SWARM_JAVA_HOME}/bin/java && \
    alternatives --install /usr/bin/java java /opt/java/jdk${JAVA_VERSION}/bin/java 100 && \
    rm -rf /tmp/* && rm -rf /var/log/*

# install maven
ENV MAVEN_VERSION=3.3.9
ENV M2_HOME=/usr/local/maven
RUN wget --directory-prefix=/tmp \
    http://mirror.synyx.de/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar xzf /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /usr/local && rm -rf /tmp/* && \
    cd /usr/local &&  ln -s apache-maven-${MAVEN_VERSION} maven && \
    alternatives --install /usr/bin/mvn mvn /usr/local/maven/bin/mvn 100

# install gradle
ENV GRADLE_VERSION=2.14.1
ENV GRADLE_HOME=/usr/local/gradle
RUN wget --directory-prefix=/tmp \
    https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip /tmp/gradle-${GRADLE_VERSION}-bin.zip -d /usr/local && rm -rf /tmp/* && \
    cd /usr/local &&  ln -s gradle-${GRADLE_VERSION} gradle && \
    alternatives --install /usr/bin/gradle gradle /usr/local/gradle/bin/gradle 100

# install firefox
# from https://hub.docker.com/r/kevensen/centos-vnc-firefox/~/dockerfile/
RUN yum install -y firefox spice-xpi; yum clean all; rm -rf /var/cache/yum

# install and setup Xvfb
# from https://github.com/SeleniumHQ/docker-selenium/tree/master/NodeBase
RUN yum install -y xorg-x11-server-Xvfb dbus-x11
RUN dbus-uuidgen > /etc/machine-id

# Switch back to user jenkins
USER $CONTAINER_UID
