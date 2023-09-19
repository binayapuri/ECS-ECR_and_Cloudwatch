variable "container_name" {
  default = "bp-test"
}

variable "linux_parameters" {
  description = "Linux-specific modifications that are applied to the container, such as Linux kernel capabilities. For more information see [KernelCapabilities](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_KernelCapabilities.html)"
  type        = any
  default     = {
    "initProcessEnabled": true
  }
}
