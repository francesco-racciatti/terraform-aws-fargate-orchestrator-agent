#
# Required variables
#
variable "name" {
  description = "Identifier for module resources"
  type        = string
  default     = "sysdig-fargate-orchestrator"
}

variable "vpc_id" {
  description = "ID of the VPC where the orchestrator should be installed"
  type        = string
}

variable "access_key" {
  description = "Sysdig Access Key, as either clear text or SecretsManager-backed secret reference"
  type        = string
  sensitive   = true
  validation {
    # Expected pattern "arn:aws:secretsmanager:region:accountId:secret:secretName[:jsonKey:versionStage:versionId]"
    condition = (startswith(var.access_key, "arn:aws:secretsmanager:")
      ? (can(regex("arn:aws:secretsmanager:[^:]+:[^:]+:secret:[^:]+(:[^:]*:[^:]*:[^:]*)?", var.access_key)) ? true : false)
      : true
    )
    error_message = "The string did not match the expected pattern 'arn:aws:secretsmanager:region:accountId:secret:secretName[:jsonKey:versionStage:versionId]'"
  }
}

locals {
  do_fetch_secret_access_key = startswith(var.access_key, "arn:aws:secretsmanager:") ? true : false
  do_fetch_secret_http_proxy_password = startswith(var.http_proxy_configuration.proxy_password, "arn:aws:secretsmanager:") ? true : false
}

variable "subnets" {
  description = "A list of subnets that can access the internet and are reachable by instrumented services. The subnets must be in at least 2 different AZs."
  type        = list(string)
}

#
# Optional variables
#
variable "orchestrator_port" {
  description = "Port for the workload agent to connect"
  type        = number
  default     = 6667
}

variable "agent_image" {
  description = "Orchestrator agent image"
  type        = string
  default     = "quay.io/sysdig/orchestrator-agent:latest"
}

variable "collector_host" {
  description = "Sysdig collector host"
  type        = string
  default     = "collector.sysdigcloud.com"
}

variable "collector_port" {
  description = "Sysdig collector port"
  type        = string
  default     = "6443"
}

variable "agent_tags" {
  description = "Comma separated list of tags for this agent"
  type        = string
  default     = ""
}

variable "check_collector_certificate" {
  description = "Whether to check the collector certificate when connecting. Mainly for development."
  type        = string
  default     = "true"
}

variable "assign_public_ip" {
  description = "Provisions a public IP for the service. Required when using an Internet Gateway for egress."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags for all Sysdig Fargate Orchestrator resources"
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Default tags for all Sysdig Fargate Orchestrator resources"
  type        = map(string)
  default = {
    Application = "sysdig"
    Module      = "fargate-orchestrator-agent"
  }
}

variable "collector_ca_certificate" {
  description = "Uploads the collector custom CA certificate to the orchestrator"
  type = object({
    type  = string
    value = string
    path  = string
  })
  default = ({
    type  = "base64"
    value = ""
    path  = "/ssl/collector_cert.pem"
  })
}

variable "collector_configuration" {
  description = "Advanced configuration options for the connection to the collector"
  type = object({
    ca_certificate = string
  })
  default = ({
    ca_certificate = "" # /ssl/collector_cert.pem
  })
}

variable "http_proxy_ca_certificate" {
  description = "Uploads the HTTP proxy CA certificate to the orchestrator"
  type = object({
    type  = string
    value = string
    path  = string
  })
  default = ({
    type  = "base64"
    value = ""
    path  = "/ssl/proxy_cert.pem"
  })
}

variable "http_proxy_configuration" {
  description = "Advanced configuration options for the connection to the HTTP proxy"
  type = object({
    proxy_host             = string
    proxy_port             = string
    proxy_user             = string
    proxy_password         = string
    ssl                    = string
    ssl_verify_certificate = string
    ca_certificate         = string
  })
  default = ({
    proxy_host             = ""
    proxy_port             = ""
    proxy_user             = ""
    proxy_password         = ""
    ssl                    = ""
    ssl_verify_certificate = ""
    ca_certificate         = "" # /ssl/proxy_cert.pem
  })
}
