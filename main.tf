provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "MY-IGW"
  }
}

resource "aws_subnet" "public-subnet-1" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "Public-Subnet-1"
    }
}

resource "aws_subnet" "public-subnet-2" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "Public-Subnet-2"
    }
}

resource "aws_subnet" "private-subnet-1" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "Private-Subnet-1"
    }
}

resource "aws_subnet" "private-subnet-2" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-1b"

    tags = {
        Name = "Private-Subnet-2"
    }
}

resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.my-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-igw.id
    }

    tags = {
        Name = "Public-Route-Table"
    }
}

resource "aws_route_table" "private-route-table" {
    vpc_id = aws_vpc.my-vpc.id
    
    tags = {
      Name = "Private-Route-Table"
    }
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
    subnet_id      = aws_subnet.public-subnet-1.id
    route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-route-table-association-2" {
    subnet_id      = aws_subnet.public-subnet-2.id
    route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "private-subnet-route-table-association" {
    subnet_id      = aws_subnet.private-subnet-1.id
    route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-route-table-association-2" {
    subnet_id      = aws_subnet.private-subnet-2.id
    route_table_id = aws_route_table.private-route-table.id
}

resource "aws_security_group" "nginx-rp-sg" {
    vpc_id = aws_vpc.my-vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
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
        Name = "Nginx-RP-SG"
    }  
}    


resource "aws_security_group" "backened-server-sg" {
    vpc_id = aws_vpc.my-vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]            // I will replace 0.0.0.0/0 with the bastion host IP
    }

    ingress {
        from_port   = 8001
        to_port     = 8003
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]            // I will replace 0.0.0.0/0 with nginx servers IP's through aws console once the it is created
    }    

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Backened-Server-SG"
    }  
}    


resource "aws_instance" "nginx-rp-instance-1" {
    ami           = "ami-03cabd110c0569173"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    subnet_id     = aws_subnet.public-subnet-1.id
    key_name      = "nginx"
    vpc_security_group_ids = [aws_security_group.nginx-rp-sg.id]

    tags = {
        Name = "Nginx-RP-Instance-1"
    }
}

resource "aws_instance" "nginx-rp-instance-2" {
    ami           = "ami-03cabd110c0569173"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1b"
    subnet_id     = aws_subnet.public-subnet-2.id
    key_name      = "nginx"
    vpc_security_group_ids = [aws_security_group.nginx-rp-sg.id]

    tags = {
        Name = "Nginx-RP-Instance-2"
    }
}

resource "aws_instance" "backend-server-instance-p1" {
    ami           = "ami-0612751733fbf56ef"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    subnet_id     = aws_subnet.private-subnet-1.id
    key_name      = "nginx"
    associate_public_ip_address = false
    vpc_security_group_ids = [aws_security_group.backened-server-sg.id]

    tags = {
        Name = "Backend-Server-Instance-private-1"
    }
}

resource "aws_instance" "backend-server-instance-p2" {
    ami           = "ami-0612751733fbf56ef"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1b"
    subnet_id     = aws_subnet.private-subnet-2.id
    key_name      = "nginx"
    associate_public_ip_address = false
    vpc_security_group_ids = [aws_security_group.backened-server-sg.id]

    tags = {
        Name = "Backend-Server-Instance-private-2"
    }
}