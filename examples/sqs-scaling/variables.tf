variable "queue_name" {
  description = "SQS queue name."
}

variable "queue_backlog_target_value" {
  description = "Queue backlog (in seconds) to maintain for the service when under maximum load."
  default     = "600"
}

variable "cluster_id" {
  description = "ECS cluster id."
  default     = "default"
}

variable "service_name" {
  description = "ECS service name."
}

variable "service_max_capacity" {
  description = "Maximum number of tasks that the autoscaling policy can set for the service."
  default     = "1"
}

variable "service_min_capacity" {
  description = "Minimum number of tasks that the autoscaling policy can set for the service."
  default     = "0"
}

# Queue backlog-based autoscaling configuration
variable "service_est_msgs_per_sec" {
  description = "Service to non-negative integer that represents the estimated number of messages the service can consume from its queue in one second."
  default     = "1"
}
