output "security_group_ids" {
  description = "Security group IDs keyed by CSV security-group name."
  value       = { for name, group in aws_security_group.security_groups : name => group.id }
}

output "security_group_names" {
  description = "Sorted, deduplicated security-group names from the CSV input."
  value       = local.sg_app_names
}

output "security_group_rules" {
  description = "Normalized security-group rules decoded from the CSV input."
  value       = local.sg_app_details
}

output "sgs" {
  description = "Compatibility list of created security-group IDs."
  value       = values(aws_security_group.security_groups)[*].id
}

output "sg_app_details" {
  description = "Compatibility output containing normalized CSV rules."
  value       = local.sg_app_details
}
