# Interactively authenticate to Azure account.
az login

# Create a new resource group (a container for related Azure resources).
az group create --name my325ResourceGroup --location westus

# Register the subscription to use the Azure Container Registry (ACR) service.
# ACR = a private Docker-compatible registry for storing container images in Azure.
az provider register --namespace Microsoft.ContainerRegistry

# Confirm that the ACR provider is registered (should return "Registered" when complete).
az provider show --namespace Microsoft.ContainerRegistry --query "registrationState"

# Create the Azure Container Registry (ACR)
# - `--sku Basic` is cheap
# - ACR will host your Docker images so Azure services can deploy them
az acr create --name cis325 --resource-group my325resourcegroup --sku Basic

# Authenticate Docker with ACR using a temporary access token.
# This allows pushing to private ACR from Docker.
az acr login -n cis325 --expose-token --output tsv --query accessToken |
    sudo docker login cis325.azurecr.io \
        --username 00000000-0000-0000-0000-000000000000 \
        --password-stdin

# Tag local Docker image with the ACR registry URL and version tag `v1`.
sudo docker tag sentiment-api cis325.azurecr.io/sentiment-api:v1

# Push the tagged image to private container registry in Azure.
sudo docker push cis325.azurecr.io/sentiment-api:v1

# Verify that the image was successfully uploaded to ACR.
az acr repository list --name cis325 --output table

# Register the subscription to use Azure Web Apps (App Service) for hosting containers.
az provider register --namespace Microsoft.Web

# Complete once the following command says "Registered."
az provider show --namespace Microsoft.Web --query "registrationState"

# Create an App Service Plan — defines the compute resources for hosting the web app.
# - B1 = Basic SKU
# - --is-linux = target Linux-based Docker containers
az appservice plan create \
    --name sentimentAppPlan \
    --resource-group my325resourcegroup \
    --sku B1 --is-linux

# Enable admin credentials for the ACR.
# This is required so App Service can authenticate and pull the container image.
az acr update --name cis325 --admin-enabled true

# Create the actual Web App (App Service) that will run the container.
az webapp create \
    --name sentiment-api-app \
    --resource-group my325resourcegroup \
    --plan sentimentAppPlan \
    --deployment-container-image-name cis325.azurecr.io/sentiment-api:v1

# Configure the Web App with credentials to pull from your private ACR.
# This step sets the container image and securely connects the app to the ACR using credentials.
az webapp config container set \
    --name sentiment-api-app \
    --resource-group my325resourcegroup \
    --container-image-name cis325.azurecr.io/sentiment-api:v1 \
    --container-registry-url https://cis325.azurecr.io \
    --container-registry-user "$(az acr credential show --name cis325 --query username -o tsv)" \
    --container-registry-password "$(az acr credential show --name cis325 --query passwords[0].value -o tsv)"
