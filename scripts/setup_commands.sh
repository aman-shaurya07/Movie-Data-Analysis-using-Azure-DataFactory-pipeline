#!/bin/bash

# Step 1: Create a Resource Group
az group create --name movie_pipeline_cli_group --location westeurope

# Step 2: Create a Storage Account
az storage account create \
  --name moviepipelineclistorage \
  --resource-group movie_pipeline_cli_group \
  --location westeurope \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hns true

# Step 3: Create Storage Containers
az storage container create --name input-data --account-name moviepipelineclistorage
az storage container create --name output-data --account-name moviepipelineclistorage

# Step 4: Upload Dataset
az storage blob upload --account-name moviepipelineclistorage \
  --container-name input-data \
  --name movie_dataset.csv \
  --file data/sample_movie_dataset.csv

# Step 5: Create Data Factory
az datafactory create \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --location westeurope

#   Command to get account keys(Used in next command)
az storage account keys list \
  --account-name moviepipelineclistorage \
  --resource-group movie_pipeline_cli_group \
  --query "[].{Key:value}" -o table



# Step 6: Create Linked Service
az datafactory linked-service create \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --linked-service-name StorageLinkedService \
  --properties configurations/linked_service.json

# Step 7: Create Datasets
az datafactory dataset create \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --name InputDataset \
  --properties configurations/datasets/input_dataset.json

az datafactory dataset create \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --name OutputDataset \
  --properties configurations/datasets/output_dataset.json

# Step 8: Create Data Flow
az datafactory data-flow create \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --data-flow-name MovieTransformations \
  --flow-type MappingDataFlow \
  --properties configurations/dataflow.json

# Step 9: Create Pipeline
az datafactory pipeline create \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --name MovieDataPipeline \
  --pipeline configurations/pipeline.json

# Step 10: Trigger Pipeline
az datafactory pipeline create-run \
  --resource-group movie_pipeline_cli_group \
  --factory-name moviepipeline-cli-adf \
  --name MovieDataPipeline
