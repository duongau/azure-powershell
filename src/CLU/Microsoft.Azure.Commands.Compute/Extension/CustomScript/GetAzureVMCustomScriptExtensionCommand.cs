﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

using Microsoft.Azure.Commands.Compute.Common;
using Microsoft.Azure.Commands.Compute.Models;
using Microsoft.Azure.Management.Compute;
using Newtonsoft.Json;
using System;
using System.Management.Automation;

namespace Microsoft.Azure.Commands.Compute
{
    [Cmdlet(
        VerbsCommon.Get,
        ProfileNouns.VirtualMachineCustomScriptExtension,
        DefaultParameterSetName = GetCustomScriptExtensionParamSetName),
    OutputType(
        typeof(VirtualMachineCustomScriptExtensionContext))]
    [CliCommandAlias("vm customscriptextension ls")]
    public class GetAzureVMCustomScriptExtensionCommand : VirtualMachineExtensionBaseCmdlet
    {
        protected const string GetCustomScriptExtensionParamSetName = "GetCustomScriptExtension";

        [Parameter(
           Mandatory = true,
           Position = 0,
           ValueFromPipelineByPropertyName = true,
           HelpMessage = "The resource group name.")]
        [ValidateNotNullOrEmpty]
        public string ResourceGroupName { get; set; }

        [Alias("ResourceName")]
        [Parameter(
            Mandatory = true,
            Position = 1,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "The virtual machine name.")]
        [ValidateNotNullOrEmpty]
        public string VMName { get; set; }

        [Alias("ExtensionName")]
        [Parameter(
            Mandatory = true,
            Position = 2,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "The extension name.")]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        [Parameter(
            Position = 3,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "To show the status.")]
        [ValidateNotNullOrEmpty]
        public SwitchParameter Status { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            ExecuteClientAction(() =>
            {
                if (Status)
                {
                    var result = this.VirtualMachineExtensionClient.Get(this.ResourceGroupName, this.VMName, this.Name, "instanceView");
                    var returnedExtension = result.ToPSVirtualMachineExtension(this.ResourceGroupName);

                    if (returnedExtension.Publisher.Equals(VirtualMachineCustomScriptExtensionContext.ExtensionDefaultPublisher, StringComparison.OrdinalIgnoreCase) &&
                        returnedExtension.ExtensionType.Equals(VirtualMachineCustomScriptExtensionContext.ExtensionDefaultName, StringComparison.OrdinalIgnoreCase))
                    {
                        WriteObject(new VirtualMachineCustomScriptExtensionContext(returnedExtension));
                    }
                    else
                    {
                        WriteObject(null);
                    }
                }
                else
                {
                    var result = this.VirtualMachineExtensionClient.Get(this.ResourceGroupName, this.VMName, this.Name);
                    var returnedExtension = result.ToPSVirtualMachineExtension(this.ResourceGroupName);

                    if (returnedExtension.Publisher.Equals(VirtualMachineCustomScriptExtensionContext.ExtensionDefaultPublisher, StringComparison.OrdinalIgnoreCase) &&
                        returnedExtension.ExtensionType.Equals(VirtualMachineCustomScriptExtensionContext.ExtensionDefaultName, StringComparison.OrdinalIgnoreCase))
                    {
                        WriteObject(new VirtualMachineCustomScriptExtensionContext(returnedExtension));
                    }
                    else
                    {
                        WriteObject(null);
                    }
                }
            });
        }
    }
}
