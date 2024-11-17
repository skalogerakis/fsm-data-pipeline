
# Instructions to Execute on a New Machine/VM

## Prerequisites

Ensure the following are installed:

1. **Ubuntu (Tested on Ubuntu 20.04.6)**
2. **Git**

---

## Getting Started

### 1. Clone the Repository

Clone this repository to your local machine in the `$HOME` directory:

```bash
git clone https://github.com/skalogerakis/fsm-data-pipeline.git

```

![Missing](/img/1.png)

### 2. Navigate to the Directory Containing the App

```bash

cd fsm-data-pipeline/

```

### 3. Install Dependencies

Install all the necessary dependencies by running:

```bash
./manage.sh

```

This process will take a while and will install Docker, Apache Flink, and all required dependencies so that our applications can execute successfully.

**Note:** A reboot is required after this process to ensure all changes take effect.

![Missing](/img/2.png)

## Apache Flink Configuration for S3


To access data from S3, you need to update the Flink configuration.


### 1. Open the Configuration File


```bash
nano flink/conf/flink-conf.yaml

```

### 2. Add the Following Lines


```yaml
s3.access-key: <my_access_key>
s3.secret-key: <my_secret_key>

```

Replace *\<my_access_key\>* and *\<my_secret_key\>* with your actual S3 credentials.

***Note: *** This is not recommended and in a EC2 instance should be avoided by direct accessing through correct IAM roles


## Building the Applications

To build both ***VisitProcessingApp*** and ***NetworkProcessingApp***, use the build option in the manage.sh script:

```bash
./manage.sh build

```

![Missing](/img/3.png)

## Executing the Applications


### 1. NetworkProcessingApp

Start by executing the ***NetworkProcessingApp***, as the given network file is static and does not require continuous processing:

```bash
./manage.sh network

```

During the first execution, it will take some time for Docker Compose to fetch the images for PostgreSQL and pgAdmin.

![Missing](/img/4.png)

#### Accessing Apache Flink Web UI


You can monitor the status and progress of the ***NetworkProcessingApp*** by opening a browser and navigating to:

- http://localhost:8081/

![Missing](/img/5.png)

#### Accessing PostgreSQL via pgAdmin


To interact with PostgreSQL using pgAdmin, open your browser and go to:

- http://localhost:5050/

![Missing](/img/6png)

Use the following credentials:

- Email: pgadmin4@pgadmin.org
- Password: admin1234

#### Adding a Server in pgAdmin

1. Click "Add New Server"
2. In the General tab, enter a Name of your choice.
3. In the Connection tab, fill in the following details:
    - Host name/address: postgresql_db
    - Maintenance database: productDb
    - Username: admin
    - Password: admin1234

![Missing](/img/7.png)

![Missing](/img/8.png)

#### Running Queries in pgAdmin


- Navigate to Databases → productDb
- Right-click and choose Query Tool
- You can now execute your SQL queries.

![Missing](/img/9.png)

#### Stopping the NetworkProcessingApp

To stop the NetworkProcessingApp, run:

```bash
./manage.sh stop

```

This command stops the Flink cluster but ***does not stop*** PostgreSQL or pgAdmin.

To stop and clean up PostgreSQL and pgAdmin, use:

```bash
./manage.sh kill

```

### 1. VisitProcessingApp

The ***VisitProcessingApp*** is designed to continuously monitor the assigned S3 bucket for new files:

```bash
./manage.sh visit

```

This Flink job does not terminate on its own, as it expects new files to arrive periodically in the S3 bucket.

To validate that new data has been processed, you can run queries in PostgreSQL.

![Missing](/img/10.png)

#### Stopping the VisitProcessingApp

To stop the VisitProcessingApp, execute:

```bash
./manage.sh stop

```


## Experimenting with AWS

### Technologies Used

- AWS S3 for data storage
- AWS EC2 for deploying the implementation

#### S3 Integration
The application successfully fetches data from the specified S3 bucket.

![Missing](/img/13.png)


#### EC2 Limitations
The t3.micro instance provided by the AWS Free Tier (1 GB of memory) was insufficient to run the complete pipeline.

![Missing](/img/11.png)
![Missing](/img/12.png)