variable "openstack_user_name" {
    description = "The username for the Tenant.",
    default  = ""
}

variable "openstack_tenant_name" {
    description = "The name of the Tenant.",
    default  = ""
}

variable "openstack_password" {
    description = "The password for the Tenant.",
    default  = ""
}

variable "openstack_auth_url" {
    description = "The endpoint url to connect to OpenStack.",
    default  = "https://iam.sa-chile-1.telefonicaopencloud.com/v3"
}

variable "domain_name" {
    description = "The domain naame.",
    default  = ""
}

variable "otc_region" {
    description = "The region naame.",
    default  = ""
}

variable "tenant_network" {
    description = "The network to be used.",
    default  = ""
}
