FROM buildpack-deps:stretch

ENV PERL_VERSION=5.28.2
ENV PERL_SHA256=aa95456dddb3eb1cc5475fed4e08f91876bea71fb636fba6399054dfbabed6c7

ENV NODE_VERSION=12.5.0
ENV NODE_SHA256=3bdae2fdd8f176de2b3225d073847cff9c8ea4374b2f5ed17b07d87ace64a029

ENV NPM_VERSION=6.9.2
ENV YARN_VERSION=1.16.0

RUN mkdir -p /usr/src/node && cd /usr/src/node \
  && for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
    gpg --keyserver $server --recv-keys \
      4ED778F539E3634C779C87C6D7062848A1AB005C \
      B9E2F5981AA6E0CD28160D9FF13993A75599653C \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      77984A986EBC2AA786BC0F66B01FBB92821C587A \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      A48C2BEE680E841632CD4E44F07496B3EB3C1762 && break; \
  done \
  && curl -sfSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz \
  && echo "${NODE_SHA256}  node-v${NODE_VERSION}.tar.gz" | sha256sum -cw - \
  && tar --strip-components=1 -xzf node-v${NODE_VERSION}.tar.gz -C /usr/src/node \
  && rm node-v${NODE_VERSION}.tar.gz \
  && ./configure --prefix=/usr \
  && make -j$(nproc) \
  && make install \
  && cd / \
  && npm install -g npm@${NPM_VERSION} \
  && npm install -g yarn@${YARN_VERSION} \
  && cd / \
  && rm -rf /tmp/* /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /usr/lib/node_modules/npm/man \
    /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html /usr/src/node \
  && true

## some flags from http://git.alpinelinux.org/cgit/aports/tree/main/perl/APKBUILD?id=19b23f225d6e4f25330e13144c7bf6c01e624656
RUN mkdir -p /usr/src/perl && cd /usr/src/perl \
  && curl -sfSLO https://www.cpan.org/src/5.0/perl-${PERL_VERSION}.tar.gz \
  && echo -n "${PERL_SHA256}  perl-${PERL_VERSION}.tar.gz" | sha256sum -cw - \
  && echo "-j$(nproc)" >~/.proverc \
  && tar --strip-components=1 -xzf perl-${PERL_VERSION}.tar.gz -C /usr/src/perl \
  && rm perl-${PERL_VERSION}.tar.gz \
  && ./Configure -des \
    -Duse64bitall \
    -Dcccdlflags='-fPIC' \
    -Dcccdlflags='-fPIC' \
    -Dccdlflags='-rdynamic' \
    -Dlocincpth=' ' \
    -Duselargefiles \
    -Dusethreads \
    -Duseshrplib \
    -Dd_semctl_semun \
    -Dusenm \
  && make libperl.so \
  && make -j$(nproc) \
  && true TEST_JOBS=$(nproc) make test_harness \
  && make install \
  && curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
  && chmod +x cpanm \
  && ./cpanm --no-interactive -f App::cpanminus \
  && ./cpanm --no-interactive Data::Printer LWP::UserAgent HTTP::Date PerlIO::utf8_strict POSIX::strftime::Compiler Digest::SHA Module::Signature IO::Socket::SSL \
  && ./cpanm --no-interactive -n LWP::Protocol::https \
  && cd / \
  && rm -rf ~/.cpanm ./cpanm /root/.cpanm /usr/src/perl \
  && true

WORKDIR /
