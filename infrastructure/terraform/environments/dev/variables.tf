# Variable definitions for development environment

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "masteryai"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    CostCenter   = "Training"
    Owner        = "Workshop Team"
    AutoShutdown = "true"
  }
}

variable "enable_auto_shutdown" {
  description = "Enable auto-shutdown for VMs to save costs"
  type        = bool
  default     = true
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses allowed to access resources"
  type        = list(string)
  default     = []
}

variable "github_token" {
  description = "GitHub token for GitHub provider"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}
