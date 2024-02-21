FROM ubuntu:21.04

RUN cp /etc/apt/sources.list /tmp; \
    sed -i 's/deb h/deb-src h/g' /etc/apt/sources.list; \
    cat /tmp/sources.list >> /etc/apt/sources.list

RUN apt update && apt upgrade -y && apt install git -y

RUN cat /etc/apt/sources.list

RUN DEBIAN_FRONTEND=noninteractive apt build-dep awesome lua-lgi -y
RUN apt remove lua-lgi lua-lgi-dev lua5.2 lua5.3 lua5.1 \
    liblua5.3-dev liblua5.2-dev liblua5.1-dev liblua5.1-0 \
    liblua5.1-0-dev liblua5.2-0 liblua5.3-0 -y
RUN apt install liblua5.4-dev libxcb-xfixes0-dev liblua5.4-0-dbg librsvg2-dev -y
RUN git clone https://github.com/pavouk/lgi.git
RUN sed -i 's|PKGS = |PKGS = lua |' /lgi/lgi/Makefile
RUN cd lgi && make PREFIX=/usr LUA_VERSION=5.4 && \
    make install LUA_VERSION=5.4 PREFIX=/usr

RUN git clone https://github.com/awesomewm/awesome
RUN cd awesome; sed -i 's|#error|//#error|' luaa.h
RUN cd awesome; sed -i 's|5.4.0|5.5.0|g' awesomeConfig.cmake
RUN cd awesome && make package
