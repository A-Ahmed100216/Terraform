# Terraform Task
Use Terraform to automate deployment of the nodejs app

## Creating a basic instance
* A very basic instance can be created with a few lines of code.
1. Define the provider, in this case, it is AWS, but can be changed to Azure, Google Cloud etc.
```hcl
provider "aws" {
    region = "eu-west-1"

}
```
2. An instance is created with resource keyword. Basic parameters such as the ami, instance type, and key name must be specified. Other parameters can be specified such as the security group, instance name etc. See documentation for guidance on syntax.
```hcl
resource "aws_instance" "nodejs_instance-app" {
    ami = "ami-0651ff04b9b983c9f"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    tags = {
        Name = "eng74-aminah-nodejs-app-3"
    }
    key_name = "eng74-aminah-aws-key"
}
```

## Creating a VPC
* A VPC is another resource so made in a simialr manner to an instance i.e. define the type of resource and mandatory parameters
```hcl
resource "aws_vpc" "VPC" {
    cidr_block = "13.0.0.0/16"
    instance_tenancy = "default"
    tags = {
        Name = "eng74-aminah-VPC-terraform"
    }
}
```
## Creating an Internet Gateway
* We need to specify the vpc id which we can reference dynamically by calling `resource.name_of_resource.parameter_you_want`

```hcl
resource "aws_internet_gateway" "igw-Aminah" {
    vpc_id = aws_vpc.VPC-Aminah.id
    tags = {
        Name = "eng74-aminah-igw-terraform"
    }
}
```

## Creating a Public Subnet
```hcl
resource "aws_subnet" "subnet_public" {
    vpc_id = aws_vpc.VPC-Aminah.id
    cidr_block = "13.0.1.0/24"
    tags = {
        Name = "eng74-aminah-public-subnet-terraform"
    }
}
```
## Creating a Security Group

```hcl





```
