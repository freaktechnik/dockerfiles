FROM ubuntu:14.04
MAINTAINER Jan Keromnes "janx@linux.com"

# Install Chromium build dependencies.
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list # && dpkg --add-architecture i386
RUN apt-get update -q && apt-get upgrade -qy && apt-get install -qy build-essential clang curl gdb git
RUN curl -SL https://src.chromium.org/chrome/trunk/src/build/install-build-deps.sh > /tmp/install-build-deps.sh \
 && chmod +x /tmp/install-build-deps.sh \
 && /tmp/install-build-deps.sh --no-prompt --no-arm --no-chromeos-fonts --no-nacl \
 && rm /tmp/install-build-deps.sh

# Don't be root.
RUN useradd -m user
USER user
ENV HOME /home/user
WORKDIR /home/user

# Install Chromium's depot_tools.
ENV DEPOT_TOOLS /home/user/depot_tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS
ENV PATH $PATH:$DEPOT_TOOLS
RUN echo "\n# Add Chromium's depot_tools to the PATH." >> .bashrc \
 && echo "export PATH=\"\$PATH:$DEPOT_TOOLS\"" >> .bashrc

# Create the Chromium directory.
RUN mkdir /home/user/chromium
WORKDIR chromium

# Force Chromium to build with clang.
RUN echo "{ 'GYP_DEFINES': 'clang=1' }" > /home/user/chromium/chromium.gyp_env

# Download Chromium's source code.
RUN fetch chromium --nosvn=True
WORKDIR src

# Build Chromium.
RUN ninja -C out/Release chrome -j18