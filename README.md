
# TerraSample

TerraSample is a generic portfolio project demonstrating a modular approach to infrastructure management using Terraform. This project serves as a template for showcasing best practices and standard module organization for a two tier cloud infrastructure.

![image](https://github.com/user-attachments/assets/ede43305-7678-4aa8-bd35-250ab8e4a12a)


## Project Structure
```
.
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── moduleA/
│   │   ├── README.md
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   ├── moduleB/
│   └── ...
```

## Getting Started

### Prerequisites

### Setup AWS Credentials:
As a prerequisite first, we have to set AWS credentials for both our development and production AWS accounts 
IAM configuration to `~/.aws/credentials`(For Mac) consisting of proper IAM permissions. For temporary credentials also 
add the session key.
```
[dev]
aws_access_key_id = <ACCESS_KEY>
aws_secret_access_key = <SECRET_KEY>

[prod]
aws_access_key_id = <ACCESS_KEY>
aws_secret_access_key = <SECRET_KEY>
aws_session_token= <SESSION_TOKEN>
```

### Remote Backend & Variables
1.Backend Infra setup for example for s3+dynamodb:
`backend.tf`
```tf
terraform {
  backend "s3" {
    bucket         = "<backend-infra-bucket-name>"
    encrypt        = true
    key            = "path/terraform.tfstate"
    region         = "<region>"
    dynamodb_table = "<backend-infra-lock-dynamodb-table-name>"
  }
}
```

2. Key value .tfvars configuration file example with sensetive data:
`dev.tfvars`
```tfvars
# Generic variables
project     = "terrasample"
aws_region  = "<region>"
profile     = "terrasample-dev"
environment = "dev"
```

### Initialize the Project

```bash
terraform init
```

### Basic Terraform Commands

## Basic Terraform Commands

### Changing Environment in Terraform:

Select development environment:

```bash
terraform workspace select dev
```

Select production environment:

```bash
terraform workspace select prod
```

#### Plan:

```bash
# For Development Environment
terraform workspace select dev && terraform plan -var-file="dev.tfvars"
# For Production Environment
terraform workspace select dev && terraform plan -var-file="prod.tfvars"
```

#### Apply:

```bash
# For Development Environment
terraform workspace select dev && terraform apply -var-file="dev.tfvars"
# For Production Environment
terraform workspace select dev && terraform apply -var-file="prod.tfvars"
```
