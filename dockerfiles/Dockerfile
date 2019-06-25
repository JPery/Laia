### Input arguments ###
ARG TORCH_CUDA_TAG

### Start with CUDA Torch ###
FROM mauvilsa/torch-cuda:$TORCH_CUDA_TAG

MAINTAINER Mauricio Villegas <mauricio_ville@yahoo.com>

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

### Copy source code ###
COPY . /tmp/Laia

### Install pre-requisites ###
RUN apt-get install -y --no-install-recommends \
      libgoogle-glog-dev \
      libgtest-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \

### Install warp-ctc and imgdistort ###
 && git clone https://github.com/baidu-research/warp-ctc.git /tmp/warp-ctc \
 && cd /tmp/warp-ctc \
 && git checkout 6d5b8fac130638862d97dc48ef43a8d7b5a503bb \
 && luarocks make torch_binding/rocks/warp-ctc-scm-1.rockspec \

### Install imgdistort ###
 && git clone https://github.com/jpuigcerver/imgdistort.git /tmp/imgdistort \
 && cd /tmp/imgdistort \
 && git checkout a61c22d5fb751a732b0a0795af1984829fb0b46e \
 && luarocks make torch/imgdistort-scm-1.rockspec \

### Install torch.cudnn R7 ###
 && git clone https://github.com/soumith/cudnn.torch -b R7 /tmp/cudnn.torch \
 && cd /tmp/cudnn.torch \
 && git checkout f53fc2b365421155c102066db60674fb9b802ec2 \
 && luarocks make cudnn-scm-1.rockspec \

### Install Laia ###
 && LIBRARY_PATH=$(echo "$LIBRARY_PATH" | sed 's|^:||; s|:$||; s|::|:|g;') \
 && cd /tmp/Laia \
 && luarocks make rocks/laia-scm-1.rockspec \
 && mv dockerfiles/laia-docker /usr/local/bin \
 && luarocks install lalarm \

### Remove temporal files ###
 && cd \
 && rm -fr /tmp/* \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
