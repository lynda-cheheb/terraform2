variable "subscription_id" {}
variable "client_id" {}
variable  "client_secret" {}
variable "tenant_id" {}
variable "version" {}

variable "name" {}
variable "location" {}
variable "owner" {}

variable "name_vnet" {}
variable "address_space" {
  type = "list"
}

variable "name_subnet" {}
variable "address_prefix" {}

variable "nameNsg" {}

variable "nameIpPub" {}
variable "allocation_method" {}

variable "nameNIC" {}
variable "nameNICConfig" {}

variable "vmSize" {}
variable "nameVM" {}

variable "key_data" {}

variable "nameLB" {}
variable "nameFrontIpConfig" {}
variable "nameAdressPool" {}

variable "nameAvset" {}

variable "namePubIP" {}
