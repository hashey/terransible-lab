provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# comments begin like this

#----- IAM -----

#S3_access

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "{aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
     }
   ]
}
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
        },
      "Effect": "Allow",
      "Sid": ""
      }
  ]
}
EOF
}

#----- VPC ------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "wp_vpc"
  }
}

#internet gateway

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags {
    Name = "wp_igw"
  }
}

#route tables

resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet_gateway.id}"
  }

  tags {
    Name = "wp_public route table"
  }
}

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"

  tags {
    Name = "wp_private"
  }
}

#subnets

resource "aws_subnet" "wp_public1_subnet" {
  vpc_id     = "${aws_vpc.wp_vpc.id}"
  cidr_block = "${var.cidrs["public1"]}"

  #assign public IP to the public subnets
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id     = "${aws_vpc.wp_vpc.id}"
  cidr_block = "${var.cidrs["public2"]}"

  #assign public IP to the public subnets
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "wp_public2"
  }
}

resource "aws_subnet" "wp_private1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_private1"
  }
}

resource "aws_subnet" "wp_private2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "wp_private2"
  }
}

resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "wp_rds1"
  }
}

resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "wp_rds2"
  }
}

resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds3"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"

  tags {
    Name = "wp_rds3"
  }
}

#rds subnet group

resource "aws_db_subnet_group" "wp_rds_subnetgroup" {
  name = "wp_rds_subnetgroup"

  subnet_ids = ["${aws_subnet.wp_rds1_subnet.id}",
    "${aws_subnet.wp_rds2_subnet.id}",
    "${aws_subnet.wp_rds3_subnet.id}",
  ]

  tags = {
    Name = "wp_rds_sng"
  }
}

#subnet associations

resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = "${aws_subnet.wp_public1_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = "${aws_subnet.wp_public2_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_private1_assoc" {
  subnet_id      = "${aws_subnet.wp_private1_subnet.id}"
  route_table_id = "${aws_default_route_table.wp_private_rt.id}"
}

resource "aws_route_table_association" "wp_private2_assoc" {
  subnet_id      = "${aws_subnet.wp_private2_subnet.id}"
  route_table_id = "${aws_default_route_table.wp_private_rt.id}"
}

#security groups

resource "aws_security_group" "wp_dev_sg" {
  #accessible only from your host

  name = "wp_dev_sg"
  description = "Used for access to the dev instance"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  #inbound - ssh
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    #ip for your host specified, update as needed
    cidr_blocks = ["${var.localip}"]
  }
  #inbound - http
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.localip}"]
  }
  #outbound - all
  egress {
    # port 0 = wildcard/everything
    from_port = 0
    to_port = 0
    # protocol -1 = wildcard/everything
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#public security group

#for public-facing ELB
resource "aws_security_group" "wp_public_sg" {
  name = "wp_public_sg"
  description = "Used for the elastic load balancer for public access"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  #inbound - http
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #outbound - all
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#private security groups
resource "aws_security_group" "wp_private_sg" {
  name = "wp_private_sg"
  description = "used for the private instances"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    #simply allow the entire CIDR range of the VPC
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#rds security groups
resource "aws_security_group" "wp_rds_sg" {
  name = "wp_rds_sg"
  description = "Security group used by RDS instances"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  #inbound - SQL from public/private security groups
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    
    #reference other SG's per best practice
    security_groups = ["${aws_security_group.wp_dev_sg.id}",
    "${aws_security_group.wp_public_sg.id}",
    "${aws_security_group.wp_private_sg.id}"]
  }
}

#VPC Endpoint to access S3 securely

resource "aws_vpc_endpoint" "wp_private-s3_endpoint" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  #access the s3 bucket from the specified region
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = ["${aws_vpc.wp_vpc.main_route_table_id}",
  "${aws_route_table.wp_public_rt.id}"]

  #make the policy more granular later
  policy = <<POLICY
{
    "Statement": [
      {
        "Action": "*",
        "Effect": "Allow",
        "Resource": "*",
        "Principal": "*"
      }
  ]
}
POLICY
}

#----- s3 code bucket -----

#creates a random ID for your code bucket as s3 bucket name
#must be unique across the entire namespace
resource "random_id" "wp_code_bucket" {
  byte_length = 2
}

resource "aws_s3_bucket" "code" {
  #concatenates the name and puts in decimal format
  bucket = "${var.domain_name}-${random_id.wp_code_bucket.dec}"
  acl = "private"
  #force destroy ensure that s3 removes the s3 bucket when other
  #infrastructure is torn down by terraform even though it is not backed up
  force_destroy = true

  tags {
    Name = "code bucket"
  }
}

#----- s3 data bucket -----

#----- RDS -----

resource "aws_db_instance" "wp_db" {
  #make sure they fall within the lab tier options
  
  #storage in GB
  allocated_storage = 10
  engine = "mysql"
  #update version if error
  engine_version = "5.6.27"
  #reference variable for other details
  instance_class = "${var.db_instance_class}"
  name = "${var.dbname}"
  username = "${var.dbuser}"
  password = "${var.dbpassword}"
  db_subnet_group_name = "${aws_db_subnet_group.wp_rds_subnetgroup.name}"
  vpc_security_group_ids = ["${aws_security_group.wp_rds_sg.id}"]
  
  #this causes issues with the snapshot not being allowed to be destroyed by terraform if it is missing a snapshot
  skip_final_snapshot = true
}
