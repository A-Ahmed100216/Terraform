# Terraform
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

## Creating instance for nodejs app
* This entails defining a few more parameters in the basic instance configuration, such as the subnet id and security groups.
```HCL
resource "aws_instance" "nodejs_instance-app" {
    ami = var.app_ami
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id=aws_subnet.subnet_public.id
    security_groups=[aws_security_group.app_sg.id]
    tags = {
        Name = "eng74-aminah-nodejs-app-3"
    }
    key_name = var.key_name

```
* A provisioner has also been included in the instance resource. This allows for remote execution of bash commands.
* Prior to defining the provisioner, a connection must be established as follows:
```HCL
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/eng74-aminah-aws-key.pem")}"
      host = "${self.public_ip}"
    }
```
* The provisioner simply contains the commands you wish to execute.
```HCL
    provisioner "remote-exec" {
      inline = [ "cd app/","DB_HOST=${aws_instance.nodejs_instance-db.public_ip} pm2 start app.js"]
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
* A security group can be created as a separate resource.
* Defined with ingress (inbound) and egress (outbound) rules.
* Security groups are stateful so only one egress rule is required which allows all traffic back in.
```HCL
resource "aws_security_group" "app_sg" {
  name        = "eng74-aminah-app-sg-public"
  description = "Allows traffic to app"
  vpc_id      = aws_vpc.VPC-Aminah.id

  ingress {
    description = "All http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eng74-aminah-app-sg"
  }
}
```
## Creating NACLs
* NACLs are created in a similar way to security groups, with ingress and egress rules used to define inbound and outbound traffic.
```hcl
resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.VPC-Aminah.id
  subnet_ids=[aws_subnet.subnet_public.id]

  egress {
    protocol   = "all"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name = "eng74-aminah-public-nacl-terraform"
  }
}
```

## Creating Route Tables
* Route Tables simply require the vpc id and the defined routes.
* In this example, the public route table allows all acess to the interent via the gateway id of the internet gateway previously craeted  
```HCL
resource "aws_route_table" "route_table" {
  vpc_id =  aws_vpc.VPC-Aminah.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-Aminah.id
  }

  tags = {
    Name = "eng74-aminah-public-route-terraform"
  }
}
```
* Upon creation, route tables must be associated to a subnet which is achieved with a separate resource.
* This simply requires the route table id and the id of the subnet you wish to associate with.  
```HCL
resource "aws_route_table_association" "route_table" {
  route_table_id= aws_route_table.route_table.id
  subnet_id=aws_subnet.subnet_public.id
}
```
