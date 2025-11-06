variable "ubuntu_version" {
  type = string
  default = "24.04.3"
}

variable "hostname" {
  type = string
}

variable "cloud_config_files" {
  type = list(string)
  default = []
}
