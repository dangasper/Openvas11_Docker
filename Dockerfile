FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV gvm_libs_version="v11.0.1" \
    openvas_scanner_version="v7.0.1" \
    gvmd_version="v9.0.1" \
    gsa_version="v9.0.1" \
    gvm_tools_version="2.1.0" \
    openvas_smb="v1.0.5" \
    open_scanner_protocol_daemon="v2.0.1" \
    ospd_openvas="v1.0.1" \
    python_gvm_version="v1.6.0" \
    arachni_version="1.5.1-0.5.12"

COPY install-deps.sh /tmp/install-deps.sh

RUN echo "Installing Dependancies.." && \
    bash /tmp/install-deps.sh

COPY --chown=redis:redis configs/redis.conf /etc/redis/redis.conf

RUN echo "Starting Build..." && mkdir /build

RUN cd /build && \
    wget -q https://github.com/Arachni/arachni/releases/download/v1.5.1/arachni-${arachni_version}-linux-x86_64.tar.gz && \
    tar -zxf arachni-${arachni_version}-linux-x86_64.tar.gz && \
    mv arachni-${arachni_version} /opt/arachni && \
    ln -s /opt/arachni/bin/* /usr/local/bin/ && \
    rm -rf *

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/gvm-libs/archive/$gvm_libs_version.tar.gz && \
    tar -zxf $gvm_libs_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/openvas-smb/archive/$openvas_smb.tar.gz && \
    tar -zxf $openvas_smb.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *
    
RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/gvmd/archive/$gvmd_version.tar.gz && \
    tar -zxf $gvmd_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/openvas-scanner/archive/$openvas_scanner_version.tar.gz && \
    tar -zxf $openvas_scanner_version.tar.gz && \
    cd /build/*/ && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/gsa/archive/$gsa_version.tar.gz && \
    tar -zxf $gsa_version.tar.gz && \
    cd /build/* && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && \
    make install && \
    cd /build && \
    rm -rf *

RUN pip3 install python-gvm==$python_gvm_version 

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/ospd/archive/$open_scanner_protocol_daemon.tar.gz && \
    tar -zxf $open_scanner_protocol_daemon.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *

RUN cd /build && \
    wget --no-verbose https://github.com/greenbone/ospd-openvas/archive/$ospd_openvas.tar.gz && \
    tar -zxf $ospd_openvas.tar.gz && \
    cd /build/*/ && \
    python3 setup.py install && \
    cd /build && \
    rm -rf *

RUN pip3 install gvm-tools==$gvm_tools_version && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/openvas.conf && ldconfig && cd / && rm -rf /build

COPY configs/openvas.conf /usr/local/etc/openvas/openvas.conf

COPY scripts/* /

CMD '/start.sh'

