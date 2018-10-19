#!/usr/bin/env python
import atexit
import requests
#from serials import tools
#from serials.tools import cli
from pyVmomi import vim
from pyVim.connect import SmartConnect, Disconnect
from tools import tasks
from pyVim.task import WaitForTask
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils._text import to_text, to_native
from ansible.module_utils.vmware import (find_obj, gather_vm_facts, get_all_objs, compile_folder_path_for_object, serialize_spec,vmware_argument_spec, set_vm_power_state, PyVmomi)

# disable  urllib3 warnings
if hasattr(requests.packages.urllib3, 'disable_warnings'):
    requests.packages.urllib3.disable_warnings




def get_args():
    argument_spec = vmware_argument_spec()
    argument_spec.update(dict(hostname=dict(type='str', required=True),
                              username=dict(type='str', required=True),
                              password=dict(type='str', required=True),
                              port=dict(type='int', default='443'),
                              name=dict(type='str', required=True),
                              uuid=dict(type='str'),
                              datacenter=dict(type='str'),
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


def get_vm_cdrom_device(vm):
    if vm is None:
        return None
 
    for device in vm.config.hardware.device:
        if isinstance(device, vim.vm.device.VirtualCdrom):
            return device

    return None


def main():
    args = get_args()

    # connect to vc
    si = SmartConnect(
        host=args.params['hostname'],
        user=args.params['username'],
        pwd=args.params['password'],
        port=args.params['port'])
    # disconnect vc
    atexit.register(Disconnect, si)

    content = si.RetrieveContent()
    print ('Searching for VM {}').format(args.params['name'])
    vm = get_obj(content, [vim.VirtualMachine], args.params['name'])

      
    cdrom = get_vm_cdrom_device(vm) 
         
    if cdrom is not None:  # Remove it
        deviceSpec = vim.vm.device.VirtualDeviceSpec()
        deviceSpec.device = cdrom
        deviceSpec.operation = vim.vm.device.VirtualDeviceSpec.Operation.remove
        configSpec = vim.vm.ConfigSpec(deviceChange=[deviceSpec])
        WaitForTask(vm.Reconfigure(configSpec))
        
        msg = ('CDROM successfully')
        args.exit_json(msg=msg ,changed=True)
    else:
        msg = ("CDROM not found")
        args.fail_json(msg=msg ,changed=False)
 
if __name__ == "__main__":
    main()
