FROM ubuntu:18.04

    ENV DEBIAN_FRONTEND=noninteractive
    ENV HDF5_USE_FILE_LOCKING=FALSE

   # Install common dependencies
   RUN apt-get update \
    && apt-get --yes install --no-install-recommends \
    bison \
    build-essential \
    cmake \
    flex \
    g++ \
    gcc \
    gettext-base \
    gfortran \
    git \
    libarmadillo-dev \
    libblas-dev \
    libboost-date-time-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-python-dev \
    libboost-regex-dev \
    libboost-signals-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libcfitsio-dev \
    libfftw3-dev \
    libgsl-dev \
    libgtkmm-3.0-dev \
    libhdf5-serial-dev \
    liblapacke-dev \
    liblog4cplus-1.1-9 \
    liblog4cplus-dev \
    libncurses5-dev \
    libpng-dev \
    libpython2.7-dev \
    libreadline-dev \
    libxml2-dev \
    openssh-server \
    python \
    python-numpy \
    python-pip \
    python-setuptools \
    subversion \
    vim \
    wcslib-dev \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && pip install \
    scipy \
    aplpy \
    astropy==2.0.4 \
    matplotlib==2.2.3 \
    pyvo \
    PySocks \
    python-monetdb \
    wcsaxes \
    xmlrunner

   RUN pip install --upgrade numpy 
   
   # Install casacore data
   RUN mkdir -p /opt/lofarsoft/data \
    && cd /opt/lofarsoft/data \
    && wget ftp://anonymous@ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar \
    && tar xvf WSRT_Measures.ztar \
    && rm WSRT_Measures.ztar 
   
   # Install casacore
   RUN wget https://github.com/casacore/casacore/archive/v2.4.1.tar.gz \
    && tar xvf v2.4.1.tar.gz && cd casacore-2.4.1 && mkdir build \
    && cd build \
    && cmake -DBUILD_PYTHON=True \
         -DDATA_DIR=/opt/lofarsoft/data \
         -DUSE_OPENMP=ON -DUSE_THREADS=OFF -DUSE_FFTW3=TRUE \
         -DUSE_HDF5=ON -DCXX11=ON -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
         -DCMAKE_CXX_FLAGS="-fsigned-char -O2 -DNDEBUG -march=native" ../ \
    && make -j4 && make install \
    && cd ../../ && rm -rf casacore-2.4.1 v2.4.1.tar.gz
    
   # Install casarest
   RUN git clone https://github.com/casacore/casarest.git \
    && cd casarest \
    && git checkout 2350d906194979d70448bf869bf628c24a0e4c19 \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
             -DCMAKE_PREFIX_PATH=/opt/lofarsoft ../ \
    && make -j4 && make install \
    && cd ../../ && rm -rf casarest
   
   # Install python casacore
   RUN wget https://github.com/casacore/python-casacore/archive/v3.0.0.tar.gz \
    && tar xvf v3.0.0.tar.gz && cd python-casacore-3.0.0 \
    && python setup.py build_ext -I/opt/lofarsoft/include -L/opt/lofarsoft/lib/ \
    && mkdir -p /opt/lofarsoft/lib/python2.7/site-packages/ \
    && export PYTHONPATH=/opt/lofarsoft/lib/python2.7/site-packages/ \
    && python setup.py install --prefix=/opt/lofarsoft
   
   # Install AOFlagger
   RUN wget https://sourceforge.net/projects/aoflagger/files/latest/download \
    && mv download download.tar && tar xvf download.tar \
    && cd aoflagger-2.14.0 && mkdir build && cd build \
    && cmake ../ -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
                 -DCMAKE_PREFIX_PATH=/opt/lofarsoft \
    && make -j4 && make install && cd ../../ \
    && rm -rf download.tar aoflagger-2.14.0
   
   # Install pyBDSF
   RUN git clone https://github.com/lofar-astron/PyBDSF.git \
    && export PYTHONPATH=/opt/lofarsoft/lib/python2.7/site-packages/ \
    && cd PyBDSF && python setup.py install --prefix=/opt/lofarsoft \
    && cd ../ && rm -rf PyBDSF
    
   # Install the LOFAR beam library
   RUN git clone https://github.com/lofar-astron/LOFARBeam.git \
    && cd LOFARBeam && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
             -DCMAKE_PREFIX_PATH=/opt/lofarsoft ../ \
    && make && make install \
    && cd ../../ && rm -rf LOFARBeam 
   
   # Install DP3
   RUN git clone https://github.com/lofar-astron/DP3.git \
    && cd DP3 && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
             -DCMAKE_PREFIX_PATH=/opt/lofarsoft ../ \
    && make && make install \
    && ln -s /opt/lofarsoft/bin/DPPP /opt/lofarsoft/bin/NDPPP \
    && cd ../../ && rm -rf DP3
   
   # Install LOFAR 3.2.10
   RUN svn --non-interactive -q co \
      https://svn.astron.nl/LOFAR/tags/LOFAR-Release-3_2_10/ source \
    && cd source && mkdir -p build/gnucxx11_optarch \
    && cd build/gnucxx11_optarch \
    && export PYTHONPATH=/opt/lofarsoft/lib/python2.7/site-packages/ \
    && cmake -DBUILD_PACKAGES="MS pystationresponse ParmDB pyparmdb Pipeline" -DBUILD_TESTING=OFF \
          -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
          -DCMAKE_PREFIX_PATH=/opt/lofarsoft/ \
          -DUSE_OPENMP=True ../../ \
    && make -j4 && make install && cd ../../../ && rm -rf source
    
    # Install dysco
    RUN wget https://github.com/aroffringa/dysco/archive/v1.2.tar.gz \
     && tar xvf v1.2.tar.gz && cd dysco-1.2 && mkdir build && cd build \
     && cmake ../ -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
              -DCMAKE_PREFIX_PATH=/opt/lofarsoft/ \
     && make -j4 && make install && cd ../../ \
     && rm -rf dysco-1.2 v1.2.tar.gz
     
   # Install LSMTool
   RUN git clone https://github.com/darafferty/LSMTool.git \
     && cd LSMTool \
     && export PYTHONPATH=/opt/lofarsoft/lib/python2.7/site-packages/ \
     && python setup.py install --prefix=/opt/lofarsoft/ \
     && cd ../ && rm -rf LSMTool 
   
   # Install RMextract
   RUN git clone https://github.com/lofar-astron/RMextract.git \
     && cd RMextract \
     && export PYTHONPATH=/opt/lofarsoft/lib/python2.7/site-packages/ \
     && python setup.py install --prefix=/opt/lofarsoft/ --add-lofar-utils \
     && cd ../ && rm -rf RMextract
    
   # Install wsclean
   RUN wget https://sourceforge.net/projects/wsclean/files/latest/download \
     && mv download download.tar && tar xvf download.tar \
     && cd wsclean-2.6 && mkdir build && cd build \
     && cmake ../ -DCMAKE_INSTALL_PREFIX=/opt/lofarsoft/ \
              -DCMAKE_PREFIX_PATH=/opt/lofarsoft/ \
     && make -j4 && make install && cd ../../ && rm -rf wsclean download.tar

   # Install losoto
   RUN git clone https://github.com/revoltek/losoto.git \
     && cd losoto \
     && export PYTHONPATH=/opt/lofarsoft/lib/python2.7/site-packages/ \
     && python setup.py install --prefix=/opt/lofarsoft/ \
     && cd ../ && rm -rf losoto 
