FROM gitpod/workspace-full:latest
LABEL maintainer="Swift Infrastructure <swift-infrastructure@swift.org>"
LABEL Description="Docker Container for the Swift programming language"

# -------------------------------------------------------------
# -------------------------------------------------------------
# -------------------------------------------------------------
# Swift Toolchain
# -------------------------------------------------------------
# -------------------------------------------------------------
# -------------------------------------------------------------

# RUN sudo export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && sudo apt-get -q update && \
#     sudo apt-get -q install -y \
#     libatomic1 \
#     libbsd0 \
#     libcurl4 \
#     libxml2 \
#     libedit2 \
#     libsqlite3-0 \
#     libc6-dev \
#     binutils \
#     libgcc-5-dev \
#     libstdc++-5-dev \
#     libpython2.7 \
#     tzdata \
#     git \
#     pkg-config \
#     && sudo rm -r /var/lib/apt/lists/*

RUN sudo apt-get update && sudo apt-get -q install -y \
    clang \
    libicu-dev \
    libtinfo5 \
    libncurses5 libncurses5-dev \
    libatomic1 \
    libbsd0 \
    libcurl4 \
    libxml2 \
    libedit2 \
    libsqlite3-0 \
    libc6-dev \
    binutils \
    libgcc-7-dev \
    libstdc++-7-dev \
    libpython2.7 \
    tzdata \
    git \
    pkg-config

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little
# ARG SWIFT_PLATFORM=ubuntu18.04
# ARG SWIFT_BRANCH=swift-5.0.2-release
# ARG SWIFT_VERSION=swift-5.0.2-RELEASE

# ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
#     SWIFT_BRANCH=$SWIFT_BRANCH \
#     SWIFT_VERSION=$SWIFT_VERSION

# Download GPG keys, signature and Swift package, then unpack, cleanup and execute permissions for foundation libs
# RUN SWIFT_URL=https://swift.org/builds/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz \
#     && sudo apt-get update \
#     && sudo apt-get install -y curl \
#     && sudo curl -fSsL $SWIFT_URL -o swift.tar.gz \
#     && sudo curl -fSsL $SWIFT_URL.sig -o swift.tar.gz.sig \
#     && sudo apt-get purge -y curl \
#     && sudo apt-get -y autoremove \
#     && sudo export GNUPGHOME="$(mktemp -d)" \
#     && sudo set -e; \
#         for key in \
#       # pub   4096R/ED3D1561 2019-03-22 [expires: 2021-03-21]
#       #       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
#       # uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org          
#           A62AE125BBBFBB96A6E042EC925CC1CCED3D1561 \
#         ; do \
#           sudo gpg --quiet --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#         done \
#     && sudo gpg --batch --verify --quiet swift.tar.gz.sig swift.tar.gz \
#     && sudo tar -xzf swift.tar.gz --directory / --strip-components=1 \
#     && sudo rm -r "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz \
#     && sudo chmod -R o+r /usr/lib/swift

RUN SWIFT_URL=https://swift.org/builds/swift-5.1-branch/ubuntu1804/swift-5.1-DEVELOPMENT-SNAPSHOT-2019-08-24-a/swift-5.1-DEVELOPMENT-SNAPSHOT-2019-08-24-a-ubuntu18.04.tar.gz \
    && curl -fSsL $SWIFT_URL -o swift.tar.gz \
    && sudo tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && sudo chmod -R o+r /usr/lib/swift


# Print Installed Swift Version
# RUN swift --version

# -------------------------------------------------------------
# -------------------------------------------------------------
# -------------------------------------------------------------
# Apple Sourcekit-LSP
# -------------------------------------------------------------
# -------------------------------------------------------------
# -------------------------------------------------------------
ARG NODE_VERSION=10
# FROM node:$NODE_VERSION as extension-builder
RUN npm install -g vsce
RUN git clone --depth 1 https://github.com/apple/sourcekit-lsp
# WORKDIR /sourcekit-lsp/Editors/vscode
# RUN npm install
# RUN npm run postinstall
# RUN vsce package -o ./sourcekit-lsp.vsix
RUN cd sourcekit-lsp/Editors/vscode \
    && npm install \
    && npm run postinstall \
    && vsce package -o ./sourcekit-lsp.vsix


FROM node:$NODE_VERSION as theia-builder
ARG version=latest
WORKDIR /home/theia
ADD $version.package.json ./package.json
ARG GITHUB_TOKEN
RUN yarn --cache-folder ./ycache && rm -rf ./ycache
RUN yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean


FROM satishbabariya/sourcekit-lsp
ENV DEBIAN_FRONTEND noninteractive
ARG NODE_VERSION=10
ENV NODE_VERSION $NODE_VERSION
RUN apt-get update
RUN apt-get -qq update
RUN apt-get install -y build-essential
RUN apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash
RUN apt-get install -y nodejs
RUN apt-get -y install git sudo

RUN adduser --disabled-password --gecos '' theia && \
    adduser theia sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project;

ENV HOME /home/theia
WORKDIR /home/theia
COPY --from=theia-builder /home/theia /home/theia

# Copy Sourcekit-lsp VSCode Extension to theia plugins
COPY --from=extension-builder /sourcekit-lsp/Editors/vscode/sourcekit-lsp.vsix /home/theia/plugins/
ENV THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins

EXPOSE 3000
ENV SHELL /bin/bash

USER theia
ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0" ]
