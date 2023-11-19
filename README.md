# Analytics Dev Environment (Scala and Python)

This template repository facilitates the development of Scala and Python Jupyter Notebooks. The template is containerized to facilitate using it on different Machines.

It works on PCs (AMD64) and Macs using the latest Apple Silicon architecture (ARM64).

## Requirements

You only need Docker.

## How to use it

1. Make sure you have Docker installed and running.
2. Copy the environment variables file `.env.example` to `.env` Adjust the values as needed (see next section)
3. Build and Run with VS code
    1. If you use VS code, open the menu (bottom left corner), and select `Reopen in container`. This will build the docker image, run the container, and open the root directory.
    2. Open any `ipynb` file in VScode and it will automatically open the Notebook view.
4. Build and Run manually
    1. If you prefer to build and run the container manually, you can use `docker-compose`.
        ```bash
        docker compose -f docker-compose.dev.yml up --build                        
        ```
    1. Once you've built it, you need to open another console, connect to the container.
        ```bash
        docker compose -f docker-compose.dev.yml exec scala-docker-dev-env /bin/bash
        ```
    1.  Run jupyter lab. After that, you can access it via a web browser.
        ```bash
        jupyter lab --ip 0.0.0.0
        ```

## How to configure it

### Environment variables

The `.env` file contains the environment variables that can be adjusted according to your needs. The provided versions in the `.env.example` file are the following:

   - JAVA_VERSION=8
   - SCALA_VERSION=2.12
   - PYTHON_VERSION=3.9.6
   - SPARK_VERSION=3.3.0
   - HADOOP_VERSION=3
   - ALMOND_VERSION=0.13.14


### Python libraries

Modify the `requirements.txt` file in the root of the repository to add the Python libraries that you want to install.

### Scala libraries

Using ivy from within the Notebooks, you can download the dependencies. See the examples.

## Examples

The `examples` directory contains Jupyter Notebook examples.
