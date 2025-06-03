# Shell configuration.
set shell := ["bash", "-cu"]
set windows-shell := ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

# Variables.
VENV_NAME := '.venv_cis-325'

# Cross platform virtual environment path.
# https://github.com/casey/just/issues/531#issuecomment-1434114392
VENV_PATH := if os() == 'windows' {
        `Join-Path -Path ($env:TEMP) -ChildPath '.venv_cis-325'`
    } else if os() == 'linux' {
        "/opt/.venv_cis-325"
    } else {
        "Unknown OS"
    }

# Default target
default:
    just --list

# === INSTALL DEPS ===

# Install dependencies in virtual environment.
[group('setup')]
[windows]
install-deps:
    # Creating with Python 3.11 for Tensorflow dependency.
    # https://stackoverflow.com/a/79031520

    # Note(Wences): Changed to `Start-Process`. Receiving python error 13, presumably attributed
    # to the kernel being in use. Despite being in use, requirements can still be changed. Using
    # `Start-Process` allows the process to attempt and continue if failed. If new venv is
    # desired, use `just clean` to remove existing venv.
    Start-Process -FilePath "python3.11" -ArgumentList "-m venv {{VENV_PATH}}" -Wait

    # Upgrading pip.
    {{VENV_PATH}}\Scripts\python.exe -m pip install -U pip --require-virtualenv

    # Installing python requirements.
    {{VENV_PATH}}\Scripts\pip.exe install -r requirements-{{os()}}.txt --require-virtualenv

# Install dependencies in virtual environment.
[group('setup')]
[linux]
install-deps:
    # Creating with Python 3.11 for Tensorflow dependency.
    # https://stackoverflow.com/a/79031520
    python3.11 -m venv {{VENV_PATH}}

    # Upgrading pip.
    {{VENV_PATH}}/bin/pip install -U pip --require-virtualenv

    # Installing python requirements.
    {{VENV_PATH}}/bin/pip install -r requirements-{{os()}}.txt --require-virtualenv

# Install python environment.
[group('setup')]
[windows]
install-python:
    Start-Process -FilePath "powershell" -ArgumentList "-Command choco install python311 -y" -Wait -Verb RunAs

# Install python environment.
[group('setup')]
[linux]
install-python:
    # Unavailable directly through official channels. Grabbing Python 3.11 from PPA.
    # https://askubuntu.com/a/1512163
    add-apt-repository ppa:deadsnakes/ppa -y
    apt update
    apt install python3.11 python3.11-venv -y

# Install Azure CLI.
[group('setup')]
[linux]
install-azure-cli:
    # Used to interact with Azure services directly.
    # Install and set up the CLI (v2)
    # https://learn.microsoft.com/en-us/azure/machine-learning/how-to-configure-cli?view=azureml-api-2&tabs=public#installation-on-linux
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    az extension add -n ml -y

# Install Docker.
[group('setup')]
[linux]
install-docker:
    # Downloading and installing latest version on Ubuntu 24.
    # https://www.cherryservers.com/blog/install-docker-ubuntu
    sudo apt install curl apt-transport-https ca-certificates software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install docker-ce -y

    # Adding current logged in user to docker group.
    sudo usermod -aG docker $USER
    newgrp
    groups $USER

# Install Docker (requires Chocolatey and WSL).
[group('setup')]
[windows]
install-docker:
    Start-Process -FilePath "powershell" -ArgumentList "-Command choco install docker-desktop -y --accept-license --backend=wsl-2" -Wait -Verb RunAs

# === PIP FREEZE ===

# Saving python requirements to file.
[group('setup')]
[windows]
pip-freeze:
    {{VENV_PATH}}\Scripts\pip.exe freeze > requirements-{{os()}}.txt

# Saving python requirements to file.
[group('setup')]
[linux]
pip-freeze:
    {{VENV_PATH}}/bin/pip freeze > requirements-{{os()}}.txt

# === HELPERS ==

# Returning virtual environment path for convenience.
[group('helpers')]
[windows]
venv-path:
    Write-Host "{{VENV_PATH}}"

# Returning virtual environment path for convenience.
[group('helpers')]
[linux]
venv-path:
    echo "{{VENV_PATH}}"

# Returning virtual environment path for convenience.
[group('helpers')]
[windows]
activate:
    Write-Host '& ''{{VENV_PATH}}\Scripts\activate.ps1'''

# Returning virtual environment activation script for convenience.
[group('helpers')]
[linux]
activate:
    echo "source {{VENV_PATH}}/bin/activate"

# Return MLFlow server path for convenience.
[group('helpers')]
[windows]
mlflow:
    Write-Host '{{VENV_PATH}}\Scripts\python.exe -m mlflow server --backend-store-uri ''file:///'''

# Return MLFlow server path for convenience.
[group('helpers')]
[linux]
mlflow:
    echo "{{VENV_PATH}}/bin/python -m mlflow server --backend-store-uri file:///tmp/mlflow/localserver"

# Install package in virtual environment.
[group('helpers')]
[windows]
install package:
    {{VENV_PATH}}\Scripts\pip.exe install {{package}}

# Install package in virtual environment.
[group('helpers')]
[linux]
install package:
    {{VENV_PATH}}/bin/pip install {{package}}

# === JUPYTER ===

# Returning virtual environment activation script for convenience.
[group('jupyter')]
[windows]
install-to-jupyter:
    {{VENV_PATH}}\Scripts\python.exe -m ipykernel install --user --name="{{VENV_NAME}}"

# Make virtual environment available to Jupyter notebook.
[group('jupyter')]
[linux]
install-to-jupyter:
    {{VENV_PATH}}/bin/python -m ipykernel install --user --name="{{VENV_NAME}}"

# == DOCKER ==

# Build container using Dockerfile.
[group('docker')]
[linux]
docker-build:
    sudo docker build -t sentiment-api ./api/

# Run Docker container.
[group('docker')]
[linux]
docker-run:
    sudo docker run -p 5000:5000 -itd sentiment-api

# == TEST ==

# Test local model expecting positive.
[group('test')]
[linux]
docker-test-positive:
    curl -X POST http://localhost:5000/predict -H "Content-Type: application/json" -d '{"review": "I absolutely love this product! It works perfectly."}'

# Test local model expecting negative.
[group('test')]
[linux]
docker-test-negative:
    curl -X POST http://localhost:5000/predict -H "Content-Type: application/json" -d '{"review": "I absolutely hate this product! It does not work."}'

# Test cloud model expecting positive.
[group('test')]
[linux]
cloud-test-positive:
    curl -X POST https://sentiment-api-app.azurewebsites.net/predict -H "Content-Type: application/json" -d '{"review": "I absolutely love this product! It works perfectly."}'

# Test cloud model expecting negative.
[group('test')]
[linux]
cloud-test-negative:
    curl -X POST https://sentiment-api-app.azurewebsites.net/predict -H "Content-Type: application/json" -d '{"review": "I absolutely hate this product! It does not work."}'

# Performing all pytests.
[group('test')]
pytest:
    pytest

# Pytest local API.
[group('test')]
pytest-local-api:
    pytest ./tests/test_local_api.py

# Pytest cloud API.
[group('test')]
pytest-cloud-api:
    pytest ./tests/test_cloud_api.py

# Pytest data.
[group('test')]
pytest-data:
    pytest ./tests/test_data.py

# Pytest model.
[group('test')]
pytest-model:
    pytest ./tests/test_model.py

# == CLEAN ==

# Remove python virtual environment.
[group('clean')]
[windows]
clean-venv:
    Stop-Process -Name python
    Remove-Item -Path {{VENV_PATH}} -Recurse -Force

# Remove python virtual environment.
[group('clean')]
[linux]
clean-venv:
    rm -rf "{{VENV_PATH}}"

# Remove all Docker containers in environment.
[group('clean')]
[linux]
clean-docker:
    docker ps -aq | xargs docker stop | xargs docker rm
