#!/bin/sh

set -ex

CUDA="10.1";
CUDNN="cudnn7-devel";
OS="ubuntu18.04";

mkdir -p logs;

### CUDA Torch ###
{ DS=$(date +%s);
  nvidia-docker build -t mauvilsa/torch-cuda:$CUDA-$OS --build-arg CUDA_TAG=$CUDA-$CUDNN-$OS torch-cuda;
  echo "time: $(( $(date +%s) - DS )) seconds";
} 2>logs/torch-cuda$CUDA-$OS.err >logs/torch-cuda$CUDA-$OS.log;

#SQUASH_LAYER=$(docker history mauvilsa/torch-cuda:$CUDA-$OS | awk '{if($1!="<missing>")L=$1;}END{print L;}');
#sudo docker-squash --from-layer $SQUASH_LAYER --tag mauvilsa/torch-cuda:$CUDA-$OS-squashed mauvilsa/torch-cuda:$CUDA-$OS;

cd ..;

### Laia ###
REV=$(git log --date=iso laia/Version.lua dockerfiles/Dockerfile dockerfiles/laia-docker | sed -n '/^Date:/{s|^Date: *||;s| .*||;s|-|.|g;p;}' | sort -r | head -n 1);
{ DS=$(date +%s);
  #nvidia-docker build --no-cache -t mauvilsa/laia:$REV-cuda$CUDA-$OS --build-arg TORCH_CUDA_TAG=$CUDA-$OS -f dockerfiles/Dockerfile .;
  nvidia-docker build            -t mauvilsa/laia:$REV-cuda$CUDA-$OS --build-arg TORCH_CUDA_TAG=$CUDA-$OS -f dockerfiles/Dockerfile .;
  echo "time: $(( $(date +%s) - DS )) seconds";
} 2>dockerfiles/logs/laia-cuda$CUDA-$OS.err >dockerfiles/logs/laia-cuda$CUDA-$OS.log;
