variable "region" {
  default = "us-west-2"
}

variable "pubkey" {
  default = "/root/.ssh/aws_compute_engine.pub"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "k8s" {
  cidr_block           = "10.240.0.0/24"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "kubernetes-the-hard-way"
  }
}

resource "aws_vpc_dhcp_options" "k8s" {
  domain_name         = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_vpc_dhcp_options_association" "k8s" {
  vpc_id          = "${aws_vpc.k8s.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.k8s.id}"
}

resource "aws_subnet" "k8s" {
  vpc_id     = "${aws_vpc.k8s.id}"
  cidr_block = "10.240.0.0/24"

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_internet_gateway" "k8s" {
  vpc_id = "${aws_vpc.k8s.id}"

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_route_table" "k8s" {
  vpc_id = "${aws_vpc.k8s.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.k8s.id}"
  }

  tags = {
    Name = "kubernetes"
  }
}

resource "aws_route_table_association" "k8s" {
  subnet_id      = "${aws_subnet.k8s.id}"
  route_table_id = "${aws_route_table.k8s.id}"
}

resource "aws_security_group" "k8s" {
  name        = "kubernetes"
  description = "Kubernetes security group"
  vpc_id      = "${aws_vpc.k8s.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/24", "10.200.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # May be wrong
  ingress {
    from_port   = 0
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "kubernetes"
  }
}

resource "aws_lb" "k8s" {
  name               = "kubernetes"
  subnets            = ["${aws_subnet.k8s.id}"]
  internal           = false
  load_balancer_type = "network"
}

resource "aws_lb_target_group" "k8s" {
  name        = "kubernetes"
  protocol    = "TCP"
  port        = 6443
  vpc_id      = "${aws_vpc.k8s.id}"
  target_type = "ip"
}

resource "aws_lb_target_group_attachment" "k8s" {
  count            = "${length(var.controller_ips)}"
  target_group_arn = "${aws_lb_target_group.k8s.arn}"
  target_id        = "${var.controller_ips[count.index]}"
}

resource "aws_lb_listener" "k8s" {
  load_balancer_arn = "${aws_lb.k8s.arn}"
  protocol          = "TCP"
  port              = 6443

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.k8s.arn}"
  }
}

resource "aws_key_pair" "k8s" {
  key_name   = "kubernetes"
  public_key = "${file(var.pubkey)}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "controller" {
  count                       = "${length(var.controller_ips)}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.k8s.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.k8s.id}"]
  instance_type               = "t2.small"
  private_ip                  = "${var.controller_ips[count.index]}"
  user_data                   = "name=controller-${count.index}"
  subnet_id                   = "${aws_subnet.k8s.id}"
  source_dest_check           = false

  tags = {
    Name = "controller-${count.index}"
  }
}

resource "aws_instance" "worker" {
  count                       = "${length(var.worker_ips)}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.k8s.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.k8s.id}"]
  instance_type               = "t2.medium"
  private_ip                  = "${var.worker_ips[count.index]}"
  user_data                   = "name=worker-${count.index}|pod-cidr=${var.worker_pod_cidrs[count.index]}"
  subnet_id                   = "${aws_subnet.k8s.id}"
  source_dest_check           = false

  tags = {
    Name = "worker-${count.index}"
  }
}

locals {
  worker_hostnames     = "${split(",", replace(join(",", aws_instance.worker.*.private_dns), ".${var.region}.compute.internal", ""))}"
  controller_hostnames = "${split(",", replace(join(",", aws_instance.controller.*.private_dns), ".${var.region}.compute.internal", ""))}"
}


