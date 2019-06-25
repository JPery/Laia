### Input arguments ###
ARG CUDA_TAG

### Start with NVIDIA cuDNN base image ###
FROM nvidia/cuda:$CUDA_TAG

MAINTAINER Mauricio Villegas <mauricio_ville@yahoo.com>

### Install pre-requisites ###
RUN apt-get update --fix-missing \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      cmake \
      git \
      libssl-dev \
      sudo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

### Export environment variables ###
ENV \
 LUA_PATH='/opt/torch/share/lua/5.1/?.lua;/opt/torch/share/lua/5.1/?/init.lua;./?.lua' \
 LUA_CPATH='/opt/torch/lib/lua/5.1/?.so;/opt/torch/lib/?.so;./?.so' \
 PATH=/opt/torch/bin:$PATH \
 LD_LIBRARY_PATH=/opt/torch/lib:$LD_LIBRARY_PATH \
 DYLD_LIBRARY_PATH=/opt/torch/lib:$DYLD_LIBRARY_PATH \
 LUA_CPATH='/opt/torch/lib/?.so;'$LUA_CPATH \
 TORCH_NVCC_FLAGS="-D__CUDA_NO_HALF_OPERATORS__"

### Install Torch7 dependencies ###
# https://flummox-engineering.blogspot.com/2019/04/cmake-error-building-torch-CUDAcublasdeviceLIBRARY-not-found.html
RUN git clone --single-branch --branch cuda10 --recursive https://github.com/nagadomi/distro.git ~/torch \
 && cd ~/torch \
 && git checkout 5bdfcc419a53b822cce391f1d94477c709c6ba9d \
 && bash install-deps \

### Install Torch7 ###
 && export PREFIX=/opt/torch \
 && mkdir -p $PREFIX \
 && ./install.sh -b \

### Remove temporal files ###
 && rm -fr /tmp/* ~/torch
