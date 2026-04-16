# This test file validates that aws_instance.example uses vpc_security_group_ids instead of
# security_groups to prevent idempotency issues in VPC-based environments. Using security_groups
# (name-based) causes Terraform to detect a diff on every plan in VPC contexts, resulting in
# unexpected instance replacement during routine applies. This test enforces the use of
# vpc_security_group_ids (ID-based) which is stable across plan/apply cycles and prevents
# force-replace behavior.

variables {
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "your-key-pair-name"
  region        = "us-west-2"
}

run "verify_instance_uses_vpc_security_group_ids_not_security_groups" {
  command = plan

  assert {
    condition     = aws_instance.example.vpc_security_group_ids != null
    error_message = "aws_instance.example must use vpc_security_group_ids (ID-based) instead of security_groups (name-based) to avoid drift detection and force-replace in VPC environments."
  }

  assert {
    condition     = length(aws_instance.example.vpc_security_group_ids) > 0
    error_message = "aws_instance.example.vpc_security_group_ids must contain at least one security group ID to ensure VPC-compatible security group attachment."
  }
}

run "verify_instance_security_groups_attribute_is_empty" {
  command = plan

  assert {
    condition     = length(aws_instance.example.security_groups) == 0
    error_message = "aws_instance.example must not use the security_groups attribute. Using security_groups (name-based) in a VPC context causes idempotency failures and can trigger instance replacement on every apply. Use vpc_security_group_ids instead."
  }
}

run "verify_security_group_id_reference_is_used" {
  command = plan

  assert {
    condition     = contains(tolist(aws_instance.example.vpc_security_group_ids), aws_security_group.example.id)
    error_message = "aws_instance.example.vpc_security_group_ids must reference aws_security_group.example.id (not aws_security_group.example.name) to ensure stable, idempotent security group association in VPC environments."
  }
}

run "verify_no_force_replace_conditions_from_security_group_naming" {
  command = plan

  assert {
    condition     = aws_instance.example.vpc_security_group_ids != null && length(aws_instance.example.vpc_security_group_ids) > 0 && length(aws_instance.example.security_groups) == 0
    error_message = "Idempotency check failed: aws_instance.example must exclusively use vpc_security_group_ids with no security_groups references. Mixed or name-based security group references will cause continuous drift detection and force-replace on re-apply in VPC environments."
  }

  assert {
    condition     = aws_instance.example.ami != null && aws_instance.example.ami != ""
    error_message = "aws_instance.example.ami must be set to a valid AMI ID to ensure a complete and valid instance configuration."
  }

  assert {
    condition     = aws_instance.example.instance_type != null && aws_instance.example.instance_type != ""
    error_message = "aws_instance.example.instance_type must be set to ensure a complete and valid instance configuration."
  }
}