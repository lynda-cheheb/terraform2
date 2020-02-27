#create resource group==========================================================================
resource "azurerm_resource_group" "rg" {
  name= "${var.name}"
  location= "${var.location}"

  tags {
    owner = "${var.owner}"
  }
}

#===create an IP Public to the resource group==========================================================
resource "azurerm_public_ip" "myFirstPubIp" {
  name = "${var.nameIpPub}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method = "Static"
}

# create a load balancer================================================================
resource "azurerm_lb" "test" {
 name                = "${var.nameLB}"
 location            = "${azurerm_resource_group.rg.location}"
 resource_group_name = "${azurerm_resource_group.rg.name}"

 frontend_ip_configuration {
   name                 = "${var.nameFrontIpConfig}"
   public_ip_address_id = "${azurerm_public_ip.myFirstPubIp.id}"
 }
}
#======================demander d'ouvrire un flux pour se connecter========================================
resource "azurerm_lb_probe" "example" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
  name                = "ssh-running-probe"
  port                = 22
}

#=======================ete lb pool   écupérer les add publics du backend==================================
resource "azurerm_lb_backend_address_pool" "test" {
 resource_group_name = "${azurerm_resource_group.rg.name}"
 loadbalancer_id     = "${azurerm_lb.test.id}"
 name                = "${var.nameAdressPool}"
}
#==================================================================================
resource "azurerm_lb_rule" "lbnatrule" {
   resource_group_name            = "${azurerm_resource_group.rg.name}"
   loadbalancer_id                = "${azurerm_lb.test.id}"
   name                           = "SSH"
   protocol                       = "Tcp"
   frontend_port                  = "22"
   backend_port                   = "22"
   backend_address_pool_id        = "${azurerm_lb_backend_address_pool.test.id}"
   frontend_ip_configuration_name = "${var.nameFrontIpConfig}"
   probe_id                       = "${azurerm_lb_probe.example.id}"
}

#créer un virtual network=====================================================================
resource  "azurerm_virtual_network" "myFirstVnet"{
  name = "${var.name_vnet}"
  address_space = "${var.address_space}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

#créer un subnet==============================================================================
resource "azurerm_subnet" "myFirstSubnet"{
  name= "${var.name_subnet}"
  resource_group_name="${azurerm_resource_group.rg.name}"
  virtual_network_name="${azurerm_virtual_network.myFirstVnet.name}"
  address_prefix="${var.address_prefix}"
}

#créer un network security group (ouvrir les ports 22, 80, 443)====================================

resource "azurerm_network_security_group" "myFirstnsg" {
  name                = "${var.nameNsg}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

 security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "inbound"
    access                     = "allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

 security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


#créer network interface controller======================================================
resource "azurerm_network_interface" "myFirstNIC" {
  count  = 2
  name = "myinterfaceNW${count.index}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  ip_configuration{
    name = "${var.nameNICConfig}"
    subnet_id = "${azurerm_subnet.myFirstSubnet.id}"
    private_ip_address_allocation = "${var.allocation_method}"
   # public_ip_address_id = "${azurerm_public_ip.myFirstPubIp.id}"
    load_balancer_backend_address_pools_ids =  [ "${azurerm_lb_backend_address_pool.test.id}" ]
  }
}

#===================================================================================
resource "azurerm_managed_disk" "test" {
 count                = 2
 name                 = "datadisk_existing_${count.index}"
 location             = "${azurerm_resource_group.rg.location}"
 resource_group_name  = "${azurerm_resource_group.rg.name}"
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "1023"
}
#========================================================================================
resource "azurerm_availability_set" "avset" {
 name                         = "${var.nameAvset}"
 location                     = "${azurerm_resource_group.rg.location}"
 resource_group_name          = "${azurerm_resource_group.rg.name}"
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}
#create virtual machine===================================================================
resource "azurerm_virtual_machine" "myFirstVM"{
  count  = 2
  name = "myVM_${count.index}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"
  network_interface_ids = ["${element(azurerm_network_interface.myFirstNIC.*.id, count.index)}"]
 # network_interface_ids = ["${element("${azurerm_network_interface.myFirstNIC.id}",count.index)}"]
  vm_size = "${var.vmSize}"

  storage_os_disk{
    name ="myDisk_${count.index}"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference{
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.6"
    version = "latest"
  }
  os_profile{
    computer_name = "vmTest"
    admin_username = "vagrant"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys{
       path =  "/home/vagrant/.ssh/authorized_keys"
       key_data = "${var.key_data}"
    }
  }
#===========================================================================================

}
