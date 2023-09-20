#!/bin/bash

# See also https://www.rocker-project.org/use/singularity/
# Before you run this bash please enter this command line below
# Install NVCC
## conda install -c nvidia cuda-nvcc=11.3.58
# Configure the XLA cuda directory
## mkdir -p $CONDA_PREFIX/etc/conda/activate.d
## printf 'export XLA_FLAGS=--xla_gpu_cuda_data_dir=$CONDA_PREFIX/lib/\n' >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
## source $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
# Copy libdevice file to the required path
## mkdir -p $CONDA_PREFIX/lib/nvvm/libdevice
## cp $CONDA_PREFIX/lib/libdevice.10.bc $CONDA_PREFIX/lib/nvvm/libdevice/
# Main parameters for the script with default values
PORT=${PORT:-8789}
USER=$(whoami)
PASSWORD=${PASSWORD:-lyp}
TMPDIR=${TMPDIR:-tmp}
CONTAINER="rstudio_latest.sif"  # path to singularity container (will be automatically downloaded)
export XLA_FLAGS=--xla_gpu_cuda_data_dir=$CONDA_PREFIX/lib

# Set-up temporary paths
RSTUDIO_TMP="${TMPDIR}/$(echo -n $CONDA_PREFIX | md5sum | awk '{print $1}')"
mkdir -p $RSTUDIO_TMP/{run,var-lib-rstudio-server,local-share-rstudio}

R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
	singularity build --fakeroot $CONTAINER Singularity
fi

if [ -z "$CONDA_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

#--bind ${CONDA_PREFIX}/lib:/usr/local/cuda \ #######where the nvvm & libdevice
#--bind /usr/lib/x86_64-linux-gnu:/.singularity.d/libs \ ##########where the libcuda.so.1

echo "Starting rstudio service on port $PORT ..."
singularity exec \
	--bind $RSTUDIO_TMP/run:/run \
	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	--bind database.conf:/etc/rstudio/database.conf \
	--bind rsession.conf:/etc/rstudio/rsession.conf \
	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	--bind ${CONDA_PREFIX}:${CONDA_PREFIX} \
	--bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
	--bind ${CONDA_PREFIX}/lib:/usr/local/cuda \
        --bind /usr/lib/x86_64-linux-gnu:/.singularity.d/libs \
	--env CONDA_PREFIX=$CONDA_PREFIX \
	--env RSTUDIO_WHICH_R=$R_BIN \
	--env RETICULATE_PYTHON=$PY_BIN \
	--env PASSWORD=$PASSWORD \
	--env PORT=$PORT \
	--env USER=$USER \
	--nv \
	rstudio_latest.sif \
	/init.sh


