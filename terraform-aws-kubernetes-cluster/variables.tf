variable "region" {}
variable "cidr" {}
variable "instance" {}
variable "ami" {}
variable "credentials" {}
variable "subnet" {}
variable "keyname" {}
variable "keypath" {}
variable "inbound_ports" {
  default = [
    {
      from_port = "22",
      to_port   = "22"
    },
    {
      from_port = "80",
      to_port   = "80"
    },
    {
      from_port = "443",
      to_port   = "443"
    },
    {
      from_port = "6443",
      to_port   = "6443"
    }
  ]
}
