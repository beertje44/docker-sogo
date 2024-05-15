FROM docker.io/phusion/baseimage:jammy-1.0.4

# Install Apache, SOGo from repository
RUN apt-get update && \
    apt-get install -y wget && \
    wget -O- "https://keys.openpgp.org/vks/v1/by-fingerprint/74FFC6D72B925A34B5D356BDF8A27B36A6E2EAE9" | gpg --dearmor > /etc/apt/trusted.gpg.d/sogo.gpg && \
    echo "deb https://packages.sogo.nu/nightly/5/ubuntu/ jammy jammy" > /etc/apt/sources.list.d/SOGo.list && \
    apt-get update && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -q -y --force-yes && \
    apt-get install -y --no-install-recommends gettext-base apache2 sogo sope4.9-gdl1-postgresql memcached libssl-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Activate required Apache modules
RUN a2enmod headers proxy proxy_http rewrite ssl

# Move SOGo's data directory to /srv
RUN usermod --home /srv/lib/sogo sogo

#ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libssl.so.3

# SOGo daemons
RUN mkdir /etc/service/sogod /etc/service/apache2 /etc/service/memcached
ADD sogod.sh /etc/service/sogod/run
ADD apache2.sh /etc/service/apache2/run
ADD memcached.sh /etc/service/memcached/run

# Make GATEWAY host available, control memcached startup
RUN mkdir -p /etc/my_init.d
ADD memcached-control.sh /etc/my_init.d/

# Fix timezone
RUN echo "tzdata tzdata/Areas select Europe" > /preseed.txt
RUN echo "tzdata tzdata/Zones/Europe select Amsterdam" >> /preseed.txt
RUN debconf-set-selections /preseed.txt
RUN rm /etc/localtime /etc/timezone
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
RUN dpkg-reconfigure -f noninteractive tzdata

# Interface the environment
VOLUME /srv
EXPOSE 80 443 8800

# Baseimage init process
ENTRYPOINT ["/sbin/my_init"]
