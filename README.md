# **Movie Data Analysis Pipeline Using Azure Data Factory (CLI)**

## **Overview**
This project demonstrates a scalable and automated data pipeline for analyzing movie datasets using **Azure Data Factory (CLI)**. The pipeline performs transformations on the input data and stores the results in a designated output container.

---

## **Architecture**
### **Flow Overview**:
1. **Azure Blob Storage**: Stores raw input data and processed output.
2. **Azure Data Factory**: Manages the pipeline for data ingestion, transformation, and output.
3. **CLI Commands**: Configures resources, datasets, and activities for the pipeline.

---

## **Steps to Execute the Project**

### **Step 1: Setup Azure Resources**
1. **Create a Resource Group**:
    ```bash
    az group create --name movie_pipeline_cli_group --location westeurope
    ```

2. **Create a Storage Account**:
    ```bash
    az storage account create \
      --name moviepipelineclistorage \
      --resource-group movie_pipeline_cli_group \
      --location westeurope \
      --sku Standard_LRS \
      --kind StorageV2 \
      --hns true
    ```

3. **Create Blob Containers**:
    ```bash
    az storage container create --name input-data --account-name moviepipelineclistorage --auth-mode login
    az storage container create --name output-data --account-name moviepipelineclistorage --auth-mode login
    ```

### **Step 2: Upload Input Dataset**
1. Upload the raw dataset to the input container:
    ```bash
    az storage blob upload \
      --account-name moviepipelineclistorage \
      --container-name input-data \
      --name movie_dataset.csv \
      --file /path/to/movie_dataset.csv \
      --auth-mode login
    ```

### **Step 3: Create Azure Data Factory**
1. **Create Data Factory**:
    ```bash
    az datafactory create \
      --resource-group movie_pipeline_cli_group \
      --factory-name moviepipeline-cli-adf \
      --location westeurope
    ```

2. **Create Linked Service for Storage**:
    ```bash
    az datafactory linked-service create \
      --resource-group movie_pipeline_cli_group \
      --factory-name moviepipeline-cli-adf \
      --name StorageLinkedService \
      --properties '{
        "type": "AzureBlobStorage",
        "typeProperties": {
          "connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=moviepipelineclistorage;"
        }
      }'
    ```

### 2 **Step 4: Create Linked Service (Second Approach)**
1. **Get the Storage Account Key**:
    ```bash
    az storage account keys list \
      --account-name moviepipelineclistorage \
      --resource-group movie_pipeline_cli_group \
      --query "[].{Key:value}" -o table
    ```

2. **Create the Linked Service**:
    ```bash
    az datafactory linked-service create \
      --resource-group movie_pipeline_cli_group \
      --factory-name moviepipeline-cli-adf \
      --linked-service-name StorageLinkedService \
      --properties @configurations/linked_service.json
    ```



3. **Create Datasets**:
    - **Input Dataset**:
        ```bash
        az datafactory dataset create \
          --resource-group movie_pipeline_cli_group \
          --factory-name moviepipeline-cli-adf \
          --name InputDataset \
          --properties '{
            "type": "AzureBlob",
            "typeProperties": {
              "fileName": "movie_dataset.csv",
              "folderPath": "input-data",
              "format": {
                "type": "TextFormat",
                "columnDelimiter": ","
              }
            },
            "linkedServiceName": {
              "referenceName": "StorageLinkedService",
              "type": "LinkedServiceReference"
            }
          }'
        ```

    - **Output Dataset**:
        ```bash
        az datafactory dataset create \
          --resource-group movie_pipeline_cli_group \
          --factory-name moviepipeline-cli-adf \
          --name OutputDataset \
          --properties '{
            "type": "AzureBlob",
            "typeProperties": {
              "folderPath": "output-data",
              "format": {
                "type": "TextFormat",
                "columnDelimiter": ","
              }
            },
            "linkedServiceName": {
              "referenceName": "StorageLinkedService",
              "type": "LinkedServiceReference"
            }
          }'
        ```

### **Step 4: Create Data Flow**
1. **Data Flow with Transformations**:
    ```bash
    az datafactory data-flow create \
      --resource-group movie_pipeline_cli_group \
      --factory-name moviepipeline-cli-adf \
      --data-flow-name MovieTransformations \
      --flow-type MappingDataFlow \
      --properties '{
        "type": "MappingDataFlow",
        "description": "Data flow for movie data transformations",
        "sources": [
          {
            "name": "SourceMovies",
            "dataset": {
              "referenceName": "InputDataset",
              "type": "DatasetReference"
            },
            "type": "DelimitedTextSource"
          }
        ],
        "transformations": [
          {
            "name": "AddColumns",
            "type": "DerivedColumn",
            "columns": [
              {
                "name": "Revenue_Category",
                "expression": "iif(toFloat(Gross) >= 100000000, 'Blockbuster', iif(toFloat(Gross) >= 50000000, 'Hit', 'Average'))"
              },
              {
                "name": "Rating_Category",
                "expression": "iif(toFloat(IMDB_Rating) >= 8, 'High', iif(toFloat(IMDB_Rating) >= 6, 'Medium', 'Low'))"
              }
            ]
          }
        ],
        "sinks": [
          {
            "name": "SinkMovies",
            "dataset": {
              "referenceName": "OutputDataset",
              "type": "DatasetReference"
            },
            "type": "DelimitedTextSink"
          }
        ]
      }'
    ```

### **Step 5: Create and Run Pipeline**
1. **Create Pipeline**:
    ```bash
    az datafactory pipeline create \
      --resource-group movie_pipeline_cli_group \
      --factory-name moviepipeline-cli-adf \
      --name MovieDataPipeline \
      --pipeline '{
        "type": "Microsoft.DataFactory/factories/pipelines",
        "activities": [
          {
            "name": "MovieDataTransformations",
            "type": "DataFlow",
            "linkedServiceName": {
              "referenceName": "StorageLinkedService",
              "type": "LinkedServiceReference"
            },
            "typeProperties": {
              "dataFlow": {
                "referenceName": "MovieTransformations",
                "type": "DataFlowReference"
              }
            }
          }
        ]
      }'
    ```

2. **Run Pipeline**:
    ```bash
    az datafactory pipeline create-run \
      --resource-group movie_pipeline_cli_group \
      --factory-name moviepipeline-cli-adf \
      --name MovieDataPipeline
    ```

---

## **Project Structure**
```plaintext
movie_data_pipeline_azure_cli/
│
├── README.md             # Project documentation
├── InputDataset/         # Input data folder
├── OutputDataset/        # Transformed data folder
└── PipelineScripts/      # Scripts to create resources, datasets, and pipelines
```

---

## **Enhancements**
1. Automate pipeline triggers using **Azure Data Factory Triggers**.
2. Add monitoring and alerts using **Azure Monitor**.

---

## **License**
This project is licensed under the MIT License. See the LICENSE file for details.
