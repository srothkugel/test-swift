FROM gitpod/workspace-full:latest
LABEL maintainer="Swift Infrastructure <swift-infrastructure@swift.org>"
LABEL Description="Docker Container for the Swift programming language"

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
