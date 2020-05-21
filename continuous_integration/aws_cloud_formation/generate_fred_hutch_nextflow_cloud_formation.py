# -------------------------
# Python Standard Libraries
# -------------------------
# N/A
# -------------------------
# Third-Party Libraries
# -------------------------
from troposphere import Ref
from troposphere import Template
from troposphere.batch import ComputeEnvironment
from troposphere.batch import ComputeEnvironmentOrder
from troposphere.batch import ComputeResources
from troposphere.batch import JobQueue
from troposphere.ec2 import Tag
from troposphere.iam import Role
# -------------------------
# Custom Components
# -------------------------
from generate_generic_nextflow_cloud_formation import aws_service_tag
from generate_generic_nextflow_cloud_formation import batch_compute_environment_desired_vcpu_parameter
from generate_generic_nextflow_cloud_formation import batch_compute_environment_max_vcpu_parameter
from generate_generic_nextflow_cloud_formation import batch_compute_environment_min_vcpu_parameter
from generate_generic_nextflow_cloud_formation import batch_job_queue_priority_parameter
from generate_generic_nextflow_cloud_formation import batch_service_role
from generate_generic_nextflow_cloud_formation import cloud_resource_name_parameter
from generate_generic_nextflow_cloud_formation import description
from generate_generic_nextflow_cloud_formation import ecs_instance_role
from generate_generic_nextflow_cloud_formation import iam_instance_profile
from generate_generic_nextflow_cloud_formation import internet_gateway
from generate_generic_nextflow_cloud_formation import internet_gateway_attachment
from generate_generic_nextflow_cloud_formation import route
from generate_generic_nextflow_cloud_formation import route_table
from generate_generic_nextflow_cloud_formation import s3_bucket
from generate_generic_nextflow_cloud_formation import security_group
from generate_generic_nextflow_cloud_formation import subnet
from generate_generic_nextflow_cloud_formation import subnet_route_table_association
from generate_generic_nextflow_cloud_formation import virtual_private_cloud

# ------------------------------------------------------------------------------
# Top Level Data
# ------------------------------------------------------------------------------
# N/A

# ------------------------------------------------------------------------------
# Parameters
# ------------------------------------------------------------------------------
# N/A

# ------------------------------------------------------------------------------
# Identity and Access Management (IAM) Resources
# ------------------------------------------------------------------------------
amazon_ec2_spot_fleet_role = Role(
    title="AmazonEC2SpotFleetRole",
    Policies=[],
    ManagedPolicyArns=[
        "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole",
    ],
    AssumeRolePolicyDocument={"Statement": [{
        "Action": ["sts:AssumeRole"],
        "Effect": "Allow",
        "Principal": {"Service": ["spot.amazonaws.com", "spotfleet.amazonaws.com"]}
    }]},
    Tags=[
        Tag("service", Ref(aws_service_tag))
    ],
)

# ------------------------------------------------------------------------------
# S3 Bucket
# ------------------------------------------------------------------------------
# N/A

# ------------------------------------------------------------------------------
# Batch
# ------------------------------------------------------------------------------
spot_fleet_batch_compute_environment = ComputeEnvironment(title="ComputeEnvironment",
                                                          Type="MANAGED",
                                                          ComputeEnvironmentName=Ref(cloud_resource_name_parameter),
                                                          ComputeResources=ComputeResources(
                                                              # Type="EC2",
                                                              Type="SPOT",  # Fred Hutch mandated configurations :(
                                                              BidPercentage=50,  # Fred Hutch mandated configurations :(
                                                              ImageId="ami-0a9d84df942521898",
                                                              InstanceTypes=["optimal"],
                                                              InstanceRole=Ref(iam_instance_profile),
                                                              SecurityGroupIds=[Ref(security_group)],
                                                              SpotIamFleetRole=Ref(amazon_ec2_spot_fleet_role),
                                                              Subnets=[Ref(subnet)],
                                                              MinvCpus=Ref(batch_compute_environment_min_vcpu_parameter),
                                                              DesiredvCpus=Ref(batch_compute_environment_desired_vcpu_parameter),
                                                              MaxvCpus=Ref(batch_compute_environment_max_vcpu_parameter),
                                                          ),
                                                          ServiceRole=Ref(batch_service_role)
                                                          )
spot_fleet_batch_job_queue = JobQueue(
    title="JobQueue",
    ComputeEnvironmentOrder=[
        ComputeEnvironmentOrder(
            ComputeEnvironment=Ref(spot_fleet_batch_compute_environment),
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
faust_nextflow_template.set_version()
faust_nextflow_template.set_description(description)

# ----------------------------------------
# Parameter
# ----------------------------------------
faust_nextflow_template.add_parameter(cloud_resource_name_parameter)
faust_nextflow_template.add_parameter(aws_service_tag)
# ---
faust_nextflow_template.add_parameter(batch_compute_environment_min_vcpu_parameter)
faust_nextflow_template.add_parameter(batch_compute_environment_desired_vcpu_parameter)
faust_nextflow_template.add_parameter(batch_compute_environment_max_vcpu_parameter)
# ---
faust_nextflow_template.add_parameter(batch_job_queue_priority_parameter)

# ----------------------------------------
# Amazon Machine Image (AMI)
# ----------------------------------------
# N/A

# ----------------------------------------
# Identity and Access Management (IAM)
# ----------------------------------------
faust_nextflow_template.add_resource(batch_service_role)
faust_nextflow_template.add_resource(ecs_instance_role)
faust_nextflow_template.add_resource(iam_instance_profile)
faust_nextflow_template.add_resource(amazon_ec2_spot_fleet_role)
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
faust_nextflow_template.add_resource(spot_fleet_batch_compute_environment)
faust_nextflow_template.add_resource(spot_fleet_batch_job_queue)


def main():
    # --------------------------------------------------------------------------
    # Print Template
    # --------------------------------------------------------------------------
    print(faust_nextflow_template.to_yaml())

    # --------------------------------------------------------------------------
    # Output Template
    # --------------------------------------------------------------------------
    with open("fred_hutch_nextflow_cloud_formation.yml", "w") as file_handle:
        file_handle.write(faust_nextflow_template.to_yaml())


if __name__ == "__main__":
    # execute only if run as a script
    main()
