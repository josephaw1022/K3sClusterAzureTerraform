variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "The location for the resources"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "myVnet"
}

variable "master_subnet_name" {
  description = "The name of the master nodes subnet"
  type        = string
  default     = "master_subnet"
}

variable "worker_subnet_name" {
  description = "The name of the worker nodes subnet"
  type        = string
  default     = "worker_subnet"
}

variable "ansible_subnet_name" {
  description = "The name of the ansible host subnet"
  type        = string
  default     = "ansible_subnet"
}

variable "master_vm_name" {
  description = "The name of the master node VM"
  type        = string
  default     = "master-node"
}

variable "worker_vm_name" {
  description = "The name of the worker node VM"
  type        = string
  default     = "worker-node"
}

variable "ansible_vm_name" {
  description = "The name of the ansible host VM"
  type        = string
  default     = "ansible-host"
}

variable "admin_username" {
  description = "The admin username for the virtual machines"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "The admin password for the virtual machines"
  type        = string
}

variable "allowed_ip" {
  description = "The allowed IP address for SSH and kube API access"
  type        = string
}


variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 1
}