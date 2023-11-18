# General arguments
ARG JAVA_VERSION
ARG SCALA_VERSION
ARG PYTHON_VERSION

ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG SPARK_URL=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

ARG ALMOND_VERSION

############################### stage ###############################
# Base image
FROM maven:3.9-amazoncorretto-${JAVA_VERSION}-debian-bullseye AS base

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000

ENV WORKSPACE=/app

# Modify via ENV variables
ENV USERNAME=${USERNAME} \
  USER_UID=${USER_UID} \
  USER_GID=${USER_GID}

# Create user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
  && useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

# Install base packages
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  wget \
  && rm -rf /var/lib/apt/lists/*

############################### stage ###############################
FROM base as base-spark

ARG SPARK_VERSION
ARG SPARK_URL
ARG SCALA_VERSION
ENV SPARK_HOME=/usr/spark
ENV SPARK_CONF_DIR=/usr/spark/conf
ENV PATH=$SPARK_HOME/bin:$PATH

# Install Spark
RUN \
      wget -O spark_bin.tgz ${SPARK_URL} \
      && tar -xvzf spark_bin.tgz \
      && mv spark-* spark-${SPARK_VERSION} \
      && mkdir -p $SPARK_HOME \
      && mv spark-${SPARK_VERSION}/* $SPARK_HOME/ \
      && rm spark_bin.tgz \
      && rm -rf spark-${SPARK_VERSION} \
      && mkdir -p ${WORKSPACE}/tmp/spark/logs \
      && chmod 777 -R ${WORKSPACE} \
      && jar cv0f $SPARK_HOME/spark-libs.jar -C $SPARK_HOME/jars/ .

ENV SPARK_HISTORY_OPTS="$SPARK_HISTORY_OPTS -Dspark.history.fs.logDirectory=file://$WORKSPACE/tmp/spark/logs"


############################### stage ###############################
# Python base
FROM base-spark AS base-python

ARG PYTHON_VERSION
# Set the installation directory for Python
ENV PYTHON_INSTALL_DIR /opt/python

# IMPROVE THIS!! 
RUN apt-get update
RUN apt-get install -y --no-install-recommends build-essential gcc
RUN apt-get install -y --no-install-recommends libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev wget libffi-dev

# Download and install Python from source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz \
    && tar -xf Python-${PYTHON_VERSION}.tar.xz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --prefix=${PYTHON_INSTALL_DIR} --enable-optimizations \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tar.xz


# Set the path to the Python installation directory
ENV PATH ${PYTHON_INSTALL_DIR}/bin:$PATH

COPY requirements.txt .
RUN pip3 install -r requirements.txt
USER ${USERNAME}

############################### stage ###############################
# This stage is intended to be used for development purposes. It
# allows to develop the application within the container, e.g. using
# vscode remote containers plugin.
FROM base-python AS dev

ARG TARGETPLATFORM
ARG ALMOND_VERSION
ARG SCALA_VERSION

USER root

# Add sudo support
RUN apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Install packages for local development
RUN apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  build-essential \
  ca-certificates \
  curl \
  git \
  ssh \
  vim \
  zip unzip \
  && rm -rf /var/lib/apt/lists/*

# Change default user
USER ${USERNAME}

# Change wordkir to install coursier and almond for the default user
WORKDIR /home/${USERNAME}

# Install coursier. The URL changes depending on the architecture, so this little
# hack will set the correct URL. Only tested with ARM (Apple Silicon) and AMD64.
ARG COURSIER_URL_AMD64=https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz
ARG COURSIER_URL_M1=https://github.com/VirtusLab/coursier-m1/releases/latest/download/cs-aarch64-pc-linux.gz

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      COURSIER_URL=${COURSIER_URL_AMD64}; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      COURSIER_URL=${COURSIER_URL_M1}; \
    else \
      COURSIER_URL=${COURSIER_URL_AMD64}; \
    fi \
    && curl -fL ${COURSIER_URL} | gzip -d > cs \
    && chmod +x cs

# Install almond
RUN ./cs launch --fork almond:${ALMOND_VERSION} --scala ${SCALA_VERSION} -- --install
# RUN python3 -m spylon_kernel install --user
WORKDIR ${WORKSPACE}

CMD [ "sleep", "infinity" ]
