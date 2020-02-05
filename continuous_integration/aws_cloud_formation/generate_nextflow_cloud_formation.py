# -------------------------
# Python Standard Libraries
# -------------------------
# N/A
# -------------------------
# Third-Party Libraries
# -------------------------
from troposphere import Parameter
from troposphere import Ref
from troposphere import Template
from troposphere.batch import ComputeEnvironment
from troposphere.batch import ComputeEnvironmentOrder
from troposphere.batch import ComputeResources
from troposphere.batch import JobQueue
from troposphere.ec2 import InternetGateway
from troposphere.ec2 import Route
from troposphere.ec2 import RouteTable
from troposphere.ec2 import SecurityGroup
from troposphere.ec2 import Subnet
from troposphere.ec2 import SubnetRouteTableAssociation
from troposphere.ec2 import VPC
from troposphere.ec2 import VPCGatewayAttachment
from troposphere.ec2 import Tag
from troposphere.iam import InstanceProfile
from troposphere.iam import Role
from troposphere.s3 import Bucket
from troposphere.s3 import Private
# -------------------------
# Custom Components
# -------------------------
# N/A

# ------------------------------------------------------------------------------
# Top Level Data
# ------------------------------------------------------------------------------
description = ("This is the FAUST Nextflow Amazon Web Services(AWS) cloud"
               " formation script. It will create all the AWS infrastructure"
               " required for running the FAUST Nextflow script.")

# ------------------------------------------------------------------------------
# Parameters
# ------------------------------------------------------------------------------
# General
cloud_resource_name_parameter = Parameter(title="CloudResourceName",
                                          Default="faust-nextflow",
                                          Description=("The name to use for all"
                                                       " resources."),
                                          Type="String",
                                          MinLength=1,
                                          MaxLength=40,
                                          AllowedPattern="^[a-zA-Z0-9-_]*$")
# TODO figure out if this should be exposed as a parameter for tagging
service_tag = "rglab-faust-nextflow"

# Batch - Compute Environment
batch_compute_environment_min_vcpu_parameter = Parameter(title="BatchComputeEnvironmentMinVCPU",
                                                         Default=0,
                                                         Description=("The number of minimum vcpus"
                                                                      " that AWS Batch will ALWAYS"
                                                                      " be running. If this is"
                                                                      " greater than 0 it will reduce"
                                                                      " runtime by always having"
                                                                      " these CPUs available."
                                                                      " CAUTION: You will always be"
                                                                      " charged for these regardless"
                                                                      " if you are running FAUST."),
                                                         Type="Number")
batch_compute_environment_desired_vcpu_parameter = Parameter(title="BatchComputeEnvironmentDesiredVCPU",
                                                             Default=0,
                                                             Type="Number")
batch_compute_environment_max_vcpu_parameter = Parameter(title="BatchComputeEnvironmentMaxVCPU",
                                                         Default=10000,
                                                         Type="Number")
# Batch - Job Queue
batch_job_queue_priority_parameter = Parameter(title="BatchJobQueuePriority",
                                               Description=("Job queues with a higher"
                                                            " integer value for priority are given"
                                                            " preference for compute resources."),
                                               Default=1,
                                               Type="Number")

# ------------------------------------------------------------------------------
# Virtual Private Cloud (VPC) Resources
# ------------------------------------------------------------------------------
virtual_private_cloud = VPC(title="VPC",
                            CidrBlock="10.0.0.0/16",
                            EnableDnsHostnames=True,
                            Tags=[
                                Tag("service", service_tag)
                            ],)

subnet = Subnet(title="Subnet",
                VpcId=Ref(virtual_private_cloud),
                CidrBlock="10.0.0.0/24",
                MapPublicIpOnLaunch=True,
                Tags=[
                    Tag("service", service_tag)
                ],)

internet_gateway = InternetGateway(
    title="InternetGateway",
    Tags=[
        Tag("service", service_tag)
    ],
)

internet_gateway_attachment = VPCGatewayAttachment(
    title="InternetGatewayAttachment",
    VpcId=Ref(virtual_private_cloud),
    InternetGatewayId=Ref(internet_gateway),
)

route_table = RouteTable(
    title="RouteTable",
    VpcId=Ref(virtual_private_cloud),
    Tags=[
        Tag("service", service_tag)
    ],
)

subnet_route_table_association = SubnetRouteTableAssociation(
    title="SubnetRouteTableAssociation",
    RouteTableId=Ref(route_table),
    SubnetId=Ref(subnet),
)

route = Route(
    title="Route",
    DestinationCidrBlock="0.0.0.0/0",
    RouteTableId=Ref(route_table),
    GatewayId=Ref(internet_gateway),
)

# ------------------------------------------------------------------------------
# Identity and Access Management (IAM) Resources
# ------------------------------------------------------------------------------
ecs_instance_role = Role(
    title="ECSInstanceRole",
    Policies=[],
    ManagedPolicyArns=[
        "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    ],
    AssumeRolePolicyDocument={"Statement": [{
        "Action": ["sts:AssumeRole"],
        "Effect": "Allow",
        "Sid": "",
        "Principal": {"Service": ["ec2.amazonaws.com"]}
    }]},
    Tags=[
        Tag("service", service_tag)
    ],
)
batch_service_role = Role(
    title="BatchServiceRole",
    Policies=[],
    ManagedPolicyArns=[
        "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole",
    ],
    AssumeRolePolicyDocument={"Statement": [{
        "Action": ["sts:AssumeRole"],
        "Effect": "Allow",
        "Principal": {"Service": ["batch.amazonaws.com"]}
    }]},
    Tags=[
        Tag("service", service_tag)
    ],
)

iam_instance_profile = InstanceProfile(
    title="IAMInstanceProfilfe",
    Roles=[Ref(ecs_instance_role)],
)
security_group = SecurityGroup(title="SecurityGroup",
                               GroupDescription=("EC2 Security Group for"
                                                 " instances launched in the"
                                                 " VPC by batch"),
                               VpcId=Ref(virtual_private_cloud),
                               Tags=[
                                   Tag("service", service_tag)
                               ],
                               )

# ------------------------------------------------------------------------------
# S3 Bucket
# ------------------------------------------------------------------------------
s3_bucket = Bucket(title="S3Bucket",
                   AccessControl=Private,
                   BucketName=Ref(cloud_resource_name_parameter),
                   DeletionPolicy="Retain",  # Used so that stack delete can be performed
                   )

# ------------------------------------------------------------------------------
# Batch
# ------------------------------------------------------------------------------
batch_compute_environment = ComputeEnvironment(title="ComputeEnvironment",
                                               Type="MANAGED",
                                               ComputeEnvironmentName=Ref(cloud_resource_name_parameter),
                                               ComputeResources=ComputeResources(
                                                   Type="EC2",
                                                   ImageId="ami-0a9d84df942521898",
                                                   InstanceTypes=["optimal"],
                                                   InstanceRole=Ref(iam_instance_profile),
                                                   SecurityGroupIds=[Ref(security_group)],
                                                   Subnets=[Ref(subnet)],
                                                   MinvCpus=Ref(batch_compute_environment_min_vcpu_parameter),
                                                   DesiredvCpus=Ref(batch_compute_environment_desired_vcpu_parameter),
                                                   MaxvCpus=Ref(batch_compute_environment_max_vcpu_parameter),
                                               ),
                                               ServiceRole=Ref(batch_service_role)
                                               )
batch_job_queue = JobQueue(
    title="JobQueue",
    ComputeEnvironmentOrder=[
        ComputeEnvironmentOrder(
            ComputeEnvironment=Ref(batch_compute_environment),
            Order=1
        ),
    ],
    Priority=Ref(batch_job_queue_priority_parameter),
    JobQueueName=Ref(cloud_resource_name_parameter)
)

# ------------------------------------------------------------------------------
# Complete Template
# ------------------------------------------------------------------------------
# ----------------------------------------
# Template
# ----------------------------------------
faust_nextflow_template = Template()
faust_nextflow_template.add_version()
faust_nextflow_template.set_description(description)

# ----------------------------------------
# Parameter
# ----------------------------------------
faust_nextflow_template.add_parameter(cloud_resource_name_parameter)
# ---
faust_nextflow_template.add_parameter(batch_compute_environment_min_vcpu_parameter)
faust_nextflow_template.add_parameter(batch_compute_environment_desired_vcpu_parameter)
faust_nextflow_template.add_parameter(batch_compute_environment_max_vcpu_parameter)
# ---
faust_nextflow_template.add_parameter(batch_job_queue_priority_parameter)


# ----------------------------------------
# Amazon Machine Image (AMI)
# ----------------------------------------
# TODO: come back to this
# def AddAMI(template):
#     template.add_mapping("RegionMap", {
#         "us-east-1": {"AMI": "ami-6411e20d"},
#         "us-west-1": {"AMI": "ami-c9c7978c"},
#         "us-west-2": {"AMI": "ami-fcff72cc"},
#         "eu-west-1": {"AMI": "ami-37c2f643"},
#         "ap-southeast-1": {"AMI": "ami-66f28c34"},
#         "ap-northeast-1": {"AMI": "ami-9c03a89d"},
#         "sa-east-1": {"AMI": "ami-a039e6bd"}
#     })

# ----------------------------------------
# Identity and Access Management (IAM)
# ----------------------------------------
faust_nextflow_template.add_resource(batch_service_role)
faust_nextflow_template.add_resource(ecs_instance_role)
faust_nextflow_template.add_resource(iam_instance_profile)
faust_nextflow_template.add_resource(security_group)

# ----------------------------------------
# Virtual Private Cloud (VPC)
# ----------------------------------------
faust_nextflow_template.add_resource(virtual_private_cloud)
faust_nextflow_template.add_resource(subnet)

faust_nextflow_template.add_resource(internet_gateway)
faust_nextflow_template.add_resource(internet_gateway_attachment)

faust_nextflow_template.add_resource(route_table)
faust_nextflow_template.add_resource(route)
faust_nextflow_template.add_resource(subnet_route_table_association)

# ----------------------------------------
# S3
# ----------------------------------------
faust_nextflow_template.add_resource(s3_bucket)

# ----------------------------------------
# Batch
# ----------------------------------------
faust_nextflow_template.add_resource(batch_compute_environment)
faust_nextflow_template.add_resource(batch_job_queue)

# TODO: set these to be separate commands for running the script
# ------------------------------------------------------------------------------
# Print Template
# ------------------------------------------------------------------------------
print(faust_nextflow_template.to_yaml())

# ------------------------------------------------------------------------------
# Output Template
# ------------------------------------------------------------------------------
with open("nextflow_cloud_formation.yml", "w") as file_handle:
    file_handle.write(faust_nextflow_template.to_yaml())
