
GPGPUSIM_REPO=https://bitbucket.org/tgrogers-purdue/gpgpu-sim_distribution.git
SST_ELEMENTS_REPO=https://bitbucket.org/tgrogers-purdue/sst-elements.git
SST_TUTORIAL_REPO=https://bitbucket.org/tgrogers-purdue/sst-tutorial.git

if [ ! -n "$PIN_HOME" ]; then
	echo "ERROR ** Install PIN and set PIN_HOME";
	return;
fi

if [ ! -n "$INTEL_PIN_DIRECTORY" ]; then
	echo "ERROR ** Set INTEL_PIN_DIRECTORY";
	return;
fi

if [ ! -n "$CUDA_INSTALL_PATH" ]; then
	echo "ERROR ** Install CUDA Toolkit and set CUDA_INSTALL_PATH.";
	return;
fi

if [ ! -d "$CUDA_INSTALL_PATH" ]; then
	echo "ERROR ** CUDA_INSTALL_PATH=$CUDA_INSTALL_PATH invalid (directory does not exist)";
	return;
fi

# to run the debug build of GPGPU-Sim run:
# source setup_environment debug
NVCC_PATH=`which nvcc`;
if [ $? = 1 ]; then
	echo "";
	echo "ERROR ** nvcc (from CUDA Toolkit) was not found in PATH but required to build GPGPU-Sim.";
	echo "         Try adding $CUDA_INSTALL_PATH/bin/ to your PATH environment variable.";
	echo "         Please also be sure to read the README file if you have not done so.";
	echo "";
	return;
fi

CC_VERSION=`gcc --version | head -1 | awk '{for(i=1;i<=NF;i++){ if(match($i,/^[0-9]\.[0-9]\.[0-9]$/))  {print $i; exit 0}}}'`
if [ "$CC_VERSION" != "4.8.2" ]; then
    echo "WARNING - this setup has only been tested with gcc 4.8.2"
fi

CUDA_VERSION_STRING=`$CUDA_INSTALL_PATH/bin/nvcc --version | awk '/release/ {print $5;}' | sed 's/,//'`;
export CUDA_VERSION_NUMBER=`echo $CUDA_VERSION_STRING | sed 's/\./ /' | awk '{printf("%02u%02u", 10*int($1), 10*$2);}'`
if [ $CUDA_VERSION_NUMBER -gt 9100 -o $CUDA_VERSION_NUMBER -lt 2030  ]; then
	echo "ERROR ** GPGPU-Sim version $GPGPUSIM_VERSION_STRING not tested with CUDA version $CUDA_VERSION_STRING (please see README)";
	return
fi


# Get and configure sst-core
if [ ! -d "sst-core" ]; then
    git clone https://github.com/sstsimulator/sst-core
    unset SST_CORE_CONFIG;
fi

if [ "$SST_CORE_CONFIG" != "1" ];  then
    cd sst-core
    export SST_CORE_HOME=`pwd`
    ./autogen.sh
    ./configure --prefix=$SST_CORE_HOME
    make all -j
    make install
    export PATH=$SST_CORE_HOME/bin:$PATH
    cd -
    export SST_CORE_CONFIG="1"
else
    echo "Assumed sst-core already pulled and built"
fi

# Get and configure gpgpu-sim
if [ ! -d "gpgpu-sim_distribution" ]; then
    git clone $GPGPUSIM_REPO
    unset SST_GPGPU_SIM_CONFIG;
fi

if [ "$SST_GPGPU_SIM_CONFIG" != "1" ];  then
    cd gpgpu-sim_distribution
#    git branch $GPGPUSIM_BRANCH
#    git checkout sst_support
    source setup_environment 
    make -j
    cd -
    export SST_GPGPU_SIM_CONFIG="1"
else
    echo "Assumed gpgpu-sim_distribution configured"
fi

# Get and configure sst-elements
if [ ! -d "sst-elements" ]; then
    git clone $SST_ELEMENTS_REPO
    unset SST_ELEMENTS_CONFIG;
fi

if [ "$SST_ELEMENTS_CONFIG" != "1" ];  then
    cd sst-elements
    export SST_ELEMENTS_HOME=`pwd`
#    git branch $SST_ELEMENTS_BRANCH
#    git checkout devel_gpgpusim
    cp --preserve=links $GPGPUSIM_ROOT/lib/$GPGPUSIM_CONFIG/libcudart_mod.so $SST_ELEMENTS_HOME/src/sst/elements/Gpgpusim/
    ./autogen.sh
    ./configure --prefix=$SST_ELEMENTS_HOME --with-sst-core=$SST_CORE_HOME --with-pin=$PIN_HOME
    make all -j
    make install
    cd -
    export LD_LIBRARY_PATH=$SST_ELEMENTS_HOME/src/sst/elements/Gpgpusim/:$LD_LIBRARY_PATH
    export SST_ELEMENTS_CONFIG="1"
else
    echo "Assumed sst-elements configured"
fi

# Get and configure the sst-tutorial
if [ ! -d "sst-tutorial" ]; then
    git clone $SST_TUTORIAL_REPO
    unset SST_TUTORIAL_CONFIG;
fi

if [ "$SST_TUTORIAL_CONFIG" != "1" ];  then
    mkdir -p run_tests/vectorAdd
    export SST_TUTORIAL_CONFIG="1"
else
    echo "Assumed sst-tutorial configured"
fi
