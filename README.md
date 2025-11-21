
# TerraSample

TerraSample is a generic portfolio project demonstrating a modular approach to infrastructure management using Terraform. This project serves as a template for showcasing best practices and standard module organization for a two tier cloud infrastructure.

![image](https://github.com/user-attachments/assets/ede43305-7678-4aa8-bd35-250ab8e4a12a)


## Project Structure
```
.
├── .                                # Terraform IaC 
│   ├── environments/                # Infrastructure segments
│   │   └── dev/                     # Development segment
│   ├── modules/                     # Terraform modules
│   └── readme.md                    # Proxmox Terraform infrastructure documentation
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

[stage]
aws_access_key_id = <ACCESS_KEY>
aws_secret_access_key = <SECRET_KEY>
aws_session_token= <SESSION_TOKEN>
```



### Initialize the Project

```bash
terraform init
```

### Basic Terraform Commands

## Basic Terraform Commands

### Changing Environment in Terraform:



#### Plan:

```bash
# For Development Environment
 cd environment/dev/
 terraform plan -var-file="dev.tfvars"

```

#### Apply:

```bash
# For Development Environment
terraform apply -var-file="dev.tfvars"

```
