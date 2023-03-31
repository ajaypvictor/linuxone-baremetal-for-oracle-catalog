variable "region" {
  type        = string
  default     = "eu-gb"
  description = "Region to deploy to, e.g. eu-gb"

   validation {
    condition     = ( var.region == "eu-gb"  ||
                      var.region == "br-sao" ||
                      var.region == "ca-tor" ||
                      var.region == "jp-tok" ||
                      var.region == "us-east" )
    error_message = "Value of region must be one of eu-gb/br-sao/ca-tor/jp-tok/us-east."
  }
}

variable "zone" {
  type        = string
  default     = "2"
  description = "Zone to deploy to, e.g. 2."

  validation {
    condition     = ( var.zone == "1" ||
                      var.zone == "2" ||
                      var.zone == "3")
    error_message = "Value of zone must be one of 1/2/3."
  }
}

variable "logical_network" {
  type        = string
  description = "Name of the VPC, if the VPC doesn't exist a new VPC will be created with this name"
}

variable "profile" {
  type        = string
  default     = "Small"
  description = "L1BM Profile to be Choosen"

   validation {
    condition     = ( var.profile == "Small"  ||
                      var.profile == "Medium" )
    error_message = "Value of profile must be Small/Medium."
  }
}

variable "ssh-key" {
  type        = string
  default     = ""
  description = "SSH Key to be used"
}

