#!/usr/bin/env python
"""
Written by Nathan Prziborowski
Github: https://github.com/prziborowski
This code is released under the terms of the Apache 2
http://www.apache.org/licenses/LICENSE-2.0.html
Example script shows how to add a virtual CD-ROM device to a VM,
using a physical device and an iso path and removing the device.
"""
import atexit
import requests
#from serials import tools
#from serials.tools import cli
from pyVmomi import vim
from pyVim.connect import SmartConnect, Disconnect
from tools import tasks
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils._text import to_text, to_native
from ansible.module_utils.vmware import (find_obj, set_vm_power_state, gather_vm_facts, get_all_objs, compile_folder_path_for_object, serialize_spec,vmware_argument_spec, PyVmomi)
import sys
from pyVmomi import vim
from pyVim.connect import SmartConnect
from pyVim.task import WaitForTask


__author__ = 'prziborowski'

# Prerequisite for VM (for simplicity sake)
# is there is an existing IDE controller.


def get_args():
    argument_spec = vmware_argument_spec()
    argument_spec.update(dict(hostname=dict(type='str', required=True),
                              username=dict(type='str', required=True),
                              password=dict(type='str', required=True),
                              port=dict(type='int', default='443'),
                              name=dict(type='str'),
                              uuid=dict(type='str', required=True),
                              datacenter=dict(type='str'),
                              port_group=dict(type='str'),
                              nic_number=dict(type='str')))
    module = AnsibleModule(argument_spec=argument_spec)
    return module

def get_obj(content, vim_type, name):
    obj = None
    container = content.viewManager.CreateContainerView(
        content.rootFolder, vim_type, True)
    for c in container.view:
        if c.name == name:
            obj = c
            break
    return obj

def get_dc(si, name):
    for dc in si.content.rootFolder.childEntity:
        if dc.name == name:
            return dc
    raise Exception('Failed to find datacenter named %s' % name)


# Returns the first cdrom if any, else None.
def get_physical_cdrom(host):
    for lun in host.configManager.storageSystem.storageDeviceInfo.scsiLun:
        if lun.lunType == 'cdrom':
            return lun
    return None


 


def find_device(vm, device_type):
    result = []
    for dev in vm.config.hardware.device:
        if isinstance(dev, device_type):
            result.append(dev)
    return result


def new_cdrom_spec(controller_key, backing):
    connectable = vim.vm.device.VirtualDevice.ConnectInfo()
    connectable.allowGuestControl = True
    connectable.startConnected = True

    cdrom = vim.vm.device.VirtualCdrom()
    cdrom.controllerKey = controller_key
    cdrom.key = -1
    cdrom.connectable = connectable
    cdrom.backing = backing
    return cdrom

def get_vm_cdrom_device(vm_obj=None):
     if vm_obj is None:
         return None

     for device in vm.config.hardware.device:
         if isinstance(device, vim.vm.device.VirtualCdrom):
             return device

     return None

def main():
    args = get_args()
    si = SmartConnect(
    host=args.params['hostname'],
    user=args.params['username'],
    pwd=args.params['password'],
    port=args.params['port'])
    if args.params['datacenter']:
        dc = get_dc(si, args.params['datacenter'])
    else:
        dc = si.content.rootFolder.childEntity[0]
    dc = si.content.rootFolder.childEntity[0] # first datacenter
    searchIndex = si.content.searchIndex
    vm = searchIndex.FindChild(dc.vmFolder, args.params['name'])

  #  vm = si.content.searchIndex.FindChild(dc.vmFolder, args.params['name'])
   

    
    #cdrom = get_vm_cdrom_device(vm_obj=vm)
    cdroms = find_device(vm, vim.vm.device.VirtualCdrom)
    op = vim.vm.device.VirtualDeviceSpec.Operation
   

    if cdrom is not None:  # Remove it
        deviceSpec = vim.vm.device.VirtualDeviceSpec()
        deviceSpec.device = cdrom
        deviceSpec.operation = op.remove
        configSpec = vim.vm.ConfigSpec(deviceChange=[deviceSpec])
        WaitForTask(vm.Reconfigure(configSpec))

if __name__ == '__main__':
    main()
