provider "aws" {
	region = "eu-west-1"
}

variable "server_port" {
	description = "The port the server will use for HTTP requests."
	default = 8080
}

variable "elb_port" {
	description = "The port the load balancer will use for HTTP requests."
	default = 80
}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "instance" {
	name = "terraform-example-instance"

	ingress {
		from_port = "${var.server_port}"
		to_port = "${var.server_port}"
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_security_group" "elb" {
	name = "terraform-example-elb"

	# Particular syntax to allow all outgoing traffic
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = "${var.elb_port}"
		to_port = "${var.elb_port}"
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_launch_configuration" "example" {
	# In an instance this parameter is called "ami"
	image_id = "ami-2a7d75c0"
	instance_type = "t2.nano"

	# Security Groups are referenced by ID
	# This parameter is called vpc_security_group_ids in an instance
	security_groups = ["${aws_security_group.instance.id}"]

	user_data = <<-EOF
		#!/bin/bash
		echo "Hello, World" > index.html
		nohup busybox httpd -f -p "${var.server_port}" &
		EOF

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_elb" "example" {
	name = "terraform-asg-example"
	security_groups = ["${aws_security_group.elb.id}"]
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	
	health_check {
		healthy_threshold = 2
		unhealthy_threshold =2
		timeout = 3
		interval = 30
		target = "HTTP:${var.server_port}/"
	}

	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = "${var.server_port}"
		instance_protocol = "http"
	}
}

resource "aws_autoscaling_group" "example" {
	launch_configuration = "${aws_launch_configuration.example.id}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]	

	min_size = 2
	max_size = 10

	# Load balancers are referenced by NAME
	load_balancers = ["${aws_elb.example.name}"]
	health_check_type = "ELB"

	tag {
		key = "Name"
		value = "terraform-asg-example"
		propagate_at_launch = true
	}
}

output "elb_dns_name" {
	value = "${aws_elb.example.dns_name}"
}

