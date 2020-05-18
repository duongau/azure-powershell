﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Tests create, update, delete and read for LoadBalancerBackendPool operations
#>
function Test-LoadBalancerBackendPoolCRUD
{

    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    $backendAddressConfigName = "TestVNetRef"
    $testIpAddress = "10.0.0.5"

    try
    {
         # Create the resource group
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        # Create the Virtual Network
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        # Create Standard Azure load balancer
        New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -SKU Standard -Force

        # Create load balancer backend pool
        $backendPoolInitial = New-AzLoadBalancerBackendAddressPool -ResourceGroupName $rgname -LoadBalancerName $lbName -Name $backendAddressPoolName -Force


        $ip1 = New-AzLoadBalancerBackendAddressConfig -IpAddress $testIpAddress -Name $backendAddressConfigName -VirtualNetwork $vnet 

        # Add Ip to pool address list
        $backendPoolInitial.LoadBalancerBackendAddresses.Add($ip1)

        $backendPoolSet1 =  Set-AzLoadBalancerBackendAddressPool -InputObject $backendPoolInitial -Force
       
        Assert-NotNull  $backendPoolSet1

        Assert-AreEqual $backendAddressPoolName $backendPoolSet1.Name
        Assert-AreEqual $backendPoolInitial.Id $backendPoolSet1.Id
        Assert-AreEqual "Succeeded" $backendPoolSet1.ProvisioningState
     
        $lisOfBackendAddresses = $backendPoolSet1.LoadBalancerBackendAddresses
        Assert-True { @($lisOfBackendAddresses).Count -eq 1 }

        Assert-AreEqual $lisOfBackendAddresses[0].Name $backendAddressConfigName
        Assert-AreEqual $lisOfBackendAddresses[0].IpAddress $testIpAddress

        #remove IpAddress from list
        $backendPoolSet1.LoadBalancerBackendAddresses.Remove($backendPoolSet1.LoadBalancerBackendAddresses[0])
        $backendPoolSet2 = Set-AzLoadBalancerBackendAddressPool -InputObject $backendPoolSet1 -Force

        Assert-NotNull  $backendPoolSet2
        
        $listOfBackendAddresses2 = $backendPoolSet2.LoadBalancerBackendAddresses
        Assert-True { @($listOfBackendAddresses2).Count -eq 0 }
    }
    finally {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}


<#
.SYNOPSIS
Tests 
#>
function Test-LoadBalancerBackendPoolCreate
{

    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    $backendAddressConfigName = "TestVNetRef"
    $testIpAddress1 = "10.0.0.5"
    $testIpAddress2 = "10.0.0.6"
    $testIpAddress3 = "10.0.0.7"

    $backendAddressConfigName1 = Get-ResourceName
    $backendAddressConfigName2 = Get-ResourceName
    $backendAddressConfigName3 = Get-ResourceName

    $backendPool1 = Get-ResourceName
    $backendPool2 = Get-ResourceName
    $backendPool3 = Get-ResourceName
    $backendPool4 = Get-ResourceName

    try
    {
         # Create the resource group
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        # Create the Virtual Network
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        # Create Standard Azure load balancer
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -SKU Standard -Force

        $ip1 = New-AzLoadBalancerBackendAddressConfig -IpAddress $testIpAddress1 -Name $backendAddressConfigName1 -VirtualNetwork $vnet
        $ip2 = New-AzLoadBalancerBackendAddressConfig -IpAddress $testIpAddress2 -Name $backendAddressConfigName2 -VirtualNetwork $vnet 
        $ip3 = New-AzLoadBalancerBackendAddressConfig -IpAddress $testIpAddress3 -Name $backendAddressConfigName3 -VirtualNetwork $vnet

        $ips = @($ip1, $ip2)
        
        ## create by passing loadbalancer without Ips
        $create1 = $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPool1 -Force

        Assert-NotNull $create1

        ## create by passing loadbalancer with ips
        $create2 = $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPool2 -LoadBalancerBackendAddress $ips -Force

        Assert-NotNull $create2
        Assert-True { @($create2.LoadBalancerBackendAddresses).Count -eq 2}

        ## create by Name without ip's
        $create3 = New-AzLoadBalancerBackendAddressPool -ResourceGroupName $rgname -LoadBalancerName $lbName -Name $backendPool3 -Force

        Assert-NotNull $create3

        ## create by Name with ip's
        $create4 = New-AzLoadBalancerBackendAddressPool -ResourceGroupName $rgname -LoadBalancerName $lbName -Name $backendPool4 -LoadBalancerBackendAddress $ips -Force

        Assert-NotNull $create4
        Assert-True { @($create4.LoadBalancerBackendAddresses).Count -eq 2}
    }
    finally {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests Remove-AzLoadBalancerBackendAddressPool
#>
function Test-LoadBalancerBackendPoolDelete
{

    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    $backendAddressConfigName = Get-ResourceName
    $backendPoolName1 = Get-ResourceName
    $backendPoolName2 = Get-ResourceName
    $backendPoolName3 = Get-ResourceName
   
   try
    {
         # Create the resource group
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        # Create Standard Azure load balancer
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -SKU Standard -Force

        $b1 = $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPoolName1 -Force
        $b2 = $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPoolName2 -Force
        $b3 = $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPoolName3 -Force

        Assert-NotNull $b1
        Assert-NotNull $b2
        Assert-NotNull $b3

        ##test passing lb object via pipeline
        $lb | Remove-AzLoadBalancerBackendAddressPool -Name $backendPoolName1 -Force

        ##test passing input object
        Remove-AzLoadBalancerBackendAddressPool -InputObject $b2 -Force

        ##test passing resourceId
        Remove-AzLoadBalancerBackendAddressPool -ResourceId $b3.Id -Force

        ## confirm removed
        $r1 = $lb | Get-AzLoadBalancerBackendAddressPool -Name $backendPoolName1 -ErrorAction SilentlyContinue
        $r2 = $lb | Get-AzLoadBalancerBackendAddressPool -Name $backendPoolName2 -ErrorAction SilentlyContinue
        $r3 = $lb | Get-AzLoadBalancerBackendAddressPool -Name $backendPoolName3 -ErrorAction SilentlyContinue

        Assert-Null $r1
        Assert-Null $r2
        Assert-Null $r3
    }
    finally {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests Set-AzLoadBalancerBackendAddressPool
#>
function Test-LoadBalancerBackendPoolUpdate
{

    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent

    $testIpAddress1 = "10.0.0.5"
    $testIpAddress2 = "10.0.0.6"

    $backendAddressConfigName1 = Get-ResourceName
    $backendAddressConfigName2 = Get-ResourceName

    $backendPool1 = Get-ResourceName

    try
    {
         # Create the resource group
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        # Create the Virtual Network
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        # Create Standard Azure load balancer
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -SKU Standard -Force

        $ip1 = New-AzLoadBalancerBackendAddressConfig -IpAddress $testIpAddress1 -Name $backendAddressConfigName1 -VirtualNetwork $vnet
        $ip2 = New-AzLoadBalancerBackendAddressConfig -IpAddress $testIpAddress2 -Name $backendAddressConfigName2 -VirtualNetwork $vnet 

        $ips = @($ip1, $ip2)
       
        $unmodified = $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPool1 -Force

        Assert-NotNull $unmodified

        #Set by name and modified input object
        $unmodified.LoadBalancerBackendAddresses.Add($ip1)

        $modified1 = Set-AzLoadBalancerBackendAddressPool -InputObject $unmodified -Force
        
        Assert-NotNull $modified1
        Assert-True { @($modified1.LoadBalancerBackendAddresses).Count -eq 1}

        #Set by specific backend from piped loadbalancer and add two IP's
        $modified2 = $lb | Set-AzLoadBalancerBackendAddressPool -LoadBalancerBackendAddress $ips -Name $backendPool1 -Force

        Assert-NotNull $modified2
        Assert-True { @($modified2.LoadBalancerBackendAddresses).Count -eq 2}

        #set by ResourceId
        $modified3 = Set-AzLoadBalancerBackendAddressPool -ResourceId $unmodified.Id -LoadBalancerBackendAddress $unmodified.LoadBalancerBackendAddresses -Force

        Assert-NotNull $modified3
        Assert-True { @($modified3.LoadBalancerBackendAddresses).Count -eq 1}
    }
    finally {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}


<#
.SYNOPSIS
Tests Get-AzLoadBalancerBackendAddressPool
#>
function Test-LoadBalancerBackendPoolRead
{

    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    $backendPool1 = Get-ResourceName
    $backendPool2 = Get-ResourceName
    $backendPool3 = Get-ResourceName

    try
    {
         # Create the resource group
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        # Create Standard Azure load balancer
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -SKU Standard -Force

        $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPool1 -Force
        $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPool2 -Force
        $lb | New-AzLoadBalancerBackendAddressPool -Name $backendPool3 -Force
        
        #Get all backends under loadbalancer
        $getAllBackendPools = $lb | Get-AzLoadBalancerBackendAddressPool

        Assert-NotNull $getAllBackendPools
        Assert-True { @($getAllBackendPools).Count -eq 3 }

        #Get specific backend from loadbalancer
        $getBackendPoolByName = $lb | Get-AzLoadBalancerBackendAddressPool -Name $backendPool1

        Assert-NotNull $getBackendPoolByName

        #Get specific backend from loadbalancer
        $getBackendPoolByRgAndName = Get-AzLoadBalancerBackendAddressPool -ResourceGroupName $rgname -LoadBalancerName $lbName -Name $backendPool1

        Assert-NotNull $getBackendPoolByRgAndName

        #Get a backend by resource Id
        $getBackendPoolByResourceId = Get-AzLoadBalancerBackendAddressPool -ResourceId $getBackendPoolByRgAndName.Id
        Assert-NotNull $getBackendPoolByResourceId
    }
    finally {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}


<#
.SYNOPSIS
Tests New-AzLoadBalancerBackendAddressConfig
#>
function Test-LoadBalancerBackendAddressConfig
{

    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $lbName = Get-ResourceName
    $subnetName = Get-ResourceName

    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent

    $validIpAddress = "10.0.0.5"
    $invalidIpAddress2 = "xxxxx"

    $backendAddressConfigName1 = Get-ResourceName
    $backendAddressConfigName2 = Get-ResourceName

    try
    {
         # Create the resource group
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        # Create the Virtual Network
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $virtualNetwork = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        $ipconfig1 = New-AzLoadBalancerBackendAddressConfig -IpAddress $validIpAddress -Name $backendAddressConfigName1 -VirtualNetwork $virtualNetwork

        Assert-AreEqual $ipconfig1.Name $backendAddressConfigName1
        Assert-AreEqual $ipconfig1.IpAddress $validIpAddress
        Assert-AreEqual $ipconfig1.VirtualNetwork.Id $virtualNetwork.Id

        Assert-ThrowsLike { New-AzLoadBalancerBackendAddressConfig -IpAddress $invalidIpAddress2 -Name $backendAddressConfigName1 -VirtualNetwork $virtualNetwork} "*Invalid IPAddress*"

        $virtualNetwork.Id = ""

        Assert-ThrowsLike { New-AzLoadBalancerBackendAddressConfig -IpAddress $validIpAddress -Name $backendAddressConfigName1 -VirtualNetwork $virtualNetwork} "*Invalid Virtual Network, ID property empty*"

    }
    finally {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}