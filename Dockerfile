From httpd:2.2
MAINTAINER ababup1192

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
      bzip2 \
      ca-certificates \
      curl \
      libffi-dev \
      libgdbm3 \
      libssl-dev \
      libyaml-dev \
      procps \
      zlib1g-dev \
      libcurl4-gnutls-dev \
      libexpat1-dev \
      gettext libz-dev \
      && rm -rf /var/lib/apt/lists/*

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
&& { \
echo 'install: --no-document'; \
echo 'update: --no-document'; \
} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.1
ENV RUBY_VERSION 2.1.10
ENV RUBY_DOWNLOAD_SHA256 fb2e454d7a5e5a39eb54db0ec666f53eeb6edc593d1d2b970ae4d150b831dd20
ENV RUBYGEMS_VERSION 2.6.6

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN set -ex \
&& buildDeps=' \
autoconf \
bison \
gcc \
libbz2-dev \
libgdbm-dev \
libglib2.0-dev \
libncurses-dev \
libreadline-dev \
libxml2-dev \
libxslt-dev \
make \
wget \
ruby \
' \
&& apt-get update \
&& apt-get install -y --no-install-recommends $buildDeps \
&& rm -rf /var/lib/apt/lists/* \
&& curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
&& mkdir -p /usr/src/ruby \
&& tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
&& rm ruby.tar.gz \
&& cd /usr/src/ruby \
&& { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new && mv file.c.new file.c \
&& autoconf \
&& ./configure --disable-install-doc \
&& make -j"$(nproc)" \
&& make install \
&& gem update --system $RUBYGEMS_VERSION \
&& rm -r /usr/src/ruby \
&& cd /usr/local/src \
&& wget https://www.kernel.org/pub/software/scm/git/git-2.9.2.tar.gz \
&& tar zxvf git-2.9.2.tar.gz \
&& cd /usr/local/src/git-2.9.2 \
&& make prefix=/usr/local all \
&& make prefix=/usr/local install \
&& apt-get purge -y --auto-remove $buildDeps \
&& rm -rf /usr/local/src/git-2.9.2 
