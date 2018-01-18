#########################################################################
# Global Initialize
function Get-VmComputeNativeMethods()
{
        $signature = @'
                     [DllImport("vmcompute.dll")]
                     public static extern void HNSCall([MarshalAs(UnmanagedType.LPWStr)] string method, [MarshalAs(UnmanagedType.LPWStr)] string path, [MarshalAs(UnmanagedType.LPWStr)] string request, [MarshalAs(UnmanagedType.LPWStr)] out string response);
'@

    # Compile into runtime type
    Add-Type -MemberDefinition $signature -Namespace VmCompute.PrivatePInvoke -Name NativeMethods -PassThru
}

#########################################################################
# Configuration
#########################################################################
function Get-HnsSwitchExtensions
{
    param
    (
        [parameter(Mandatory=$true)] [string] $NetworkId
    )

    return (Get-HNSNetwork $NetworkId).Extensions
}

function Set-HnsSwitchExtension
{
    param
    (
        [parameter(Mandatory=$true)] [string] $NetworkId,
        [parameter(Mandatory=$true)] [string] $ExtensionId,
        [parameter(Mandatory=$true)] [bool]   $state
    )

    # { "Extensions": [ { "Id": "...", "IsEnabled": true|false } ] }
    $req = @{
        "Extensions"=@(@{
            "Id"=$ExtensionId;
            "IsEnabled"=$state;
        };)
    }
    Invoke-HNSRequest -Method POST -Type networks -Id $NetworkId -Data (ConvertTo-Json $req)
}

#########################################################################
# Activities
#########################################################################
function Get-HnsActivities
{
    [cmdletbinding()]Param()
    return Invoke-HNSRequest -Type activities -Method GET
}
#########################################################################
# Compartments
#########################################################################
function Get-HnsCompartment {
    [cmdletbinding()]Param()
    return Invoke-HNSRequest -Type compartments -Method GET
}

function New-HnsRoute {
    param
    (
        [parameter(Mandatory = $false)] [Guid[]] $Endpoints = $null,
        [parameter(Mandatory = $true)] [string] $DestinationPrefix,
        [parameter(Mandatory = $false)] [switch] $EncapEnabled,
        [parameter(Mandatory = $false)] [string] $NextHop
    )

    $route = @{
            Type = "ROUTE";
            DestinationPrefix = $DestinationPrefix;
            NeedEncap = $EncapEnabled.IsPresent;
    };

    if($NextHop)
    {
        $route.NextHop = $NextHop
    }


    $policyLists = @{
        References = @(
            get-endpointReferences $Endpoints;
        );

        Policies   = @(
            $route
        );
    }

    Invoke-HNSRequest -Method POST -Type policylists -Data (ConvertTo-Json  $policyLists -Depth 10)
}


function New-HnsProxyPolicy {
    param
    (
        [parameter(Mandatory = $false)] [Guid[]] $Endpoints = $null,
        [parameter(Mandatory = $false)] [string] $DestinationPrefix,
        [parameter(Mandatory = $false)] [string] $DestinationPort,
        [parameter(Mandatory = $false)] [string] $Destination,
        [parameter(Mandatory = $false)] [string[]] $ExceptionList,
        [parameter(Mandatory = $false)] [bool] $OutboundNat
    )

    $ProxyPolicy   = @{
        Type = "PROXY";
    };

    if ($DestinationPrefix) {
        $ProxyPolicy['IP'] = $DestinationPrefix
    }
    if ($DestinationPort) {
        $ProxyPolicy['Port'] = $DestinationPort
    }
    if ($ExceptionList) {
        $ProxyPolicy['ExceptionList'] = $ExceptionList
    }
    if ($Destination) {
        $ProxyPolicy['Destination'] = $Destination
    }
    if ($OutboundNat) {
        $ProxyPolicy['OutboundNat'] = $OutboundNat
    }
    foreach ($id in $Endpoints) {
        $ep = Get-HnsEndpoint -Id $id
        $ep.Policies += $ProxyPolicy

        $epu   = @{
            ID = $id;
            Policies=$ep.Policies;
        };
        Invoke-HNSRequest -Method POST -Type endpoints -Id $id -Data (ConvertTo-Json  $epu -Depth 10)
    }
}

function Remove-HnsProxyPolicy {
    param
    (
        [parameter(Mandatory = $false)] [Guid[]] $Endpoints = $null
    )

    foreach ($id in $Endpoints) {
        $ep = Get-HnsEndpoint -Id $id
        $Policies = $ep.Policies | ? { $_.Type -ne "PROXY" }

        $epu   = @{
            ID = $id;
            Policies=$Policies;
        };

        Invoke-HNSRequest -Method POST -Type endpoints -Id $id -Data (ConvertTo-Json  $epu -Depth 10)
    }


}

function New-HnsLoadBalancer {
    param
    (
        [parameter(Mandatory = $false)] [Guid[]] $Endpoints = $null,
        [parameter(Mandatory = $true)] [int] $InternalPort,
        [parameter(Mandatory = $true)] [int] $ExternalPort,
        [parameter(Mandatory = $false)] [string] $Vip,
        [parameter(Mandatory = $false)] [string] $SourceVip,
        [parameter(Mandatory = $false)] [switch] $ILB,
        [parameter(Mandatory = $false)] [switch] $DSR
    )

    $elb = @{}
    $elb.Type = "ELB"
    $elb.InternalPort = $InternalPort
    $elb.ExternalPort = $ExternalPort
    
    if(-not [String]::IsNullOrEmpty($vip))
    {
        $elb.VIPs = @()
        $elb.VIPS += $Vip
    }

    if(-not [String]::IsNullOrEmpty($SourceVip))
    {
    
        $elb.SourceVIP += $SourceVip
    }

    if($ILB.IsPresent)
    {
        $elb.ILB = $true
    }

    if($DSR.IsPresent)
    {
        $elb.IsDSR = $true
    }

  

    $policyLists = @{
        References = @(
            get-endpointReferences $Endpoints;
        );

        Policies   = @(
            $elb
        );
    }

    Invoke-HNSRequest -Method POST -Type policylists -Data ( ConvertTo-Json  $policyLists -Depth 10)
}

function get-endpointReferences {
    param
    (
        [parameter(Mandatory = $true)] [Guid[]] $Endpoints = $null
    )
    if ($Endpoints ) {
        $endpointReference = @()
        foreach ($endpoint in $Endpoints)
        {
            $endpointReference += "/endpoints/$endpoint"
        }
        return $endpointReference
    }
    return @()
}

#########################################################################
# Networks
#########################################################################
function New-HnsNetwork
{
    param
    (
        [parameter(Mandatory=$false, Position=0)]
        [string] $JsonString,
        [ValidateSet('ICS', 'Internal', 'Transparent', 'NAT', 'Overlay', 'L2Bridge', 'L2Tunnel', 'Layered', 'Private')]
        [parameter(Mandatory = $false, Position = 0)]
        [string] $Type,
        [parameter(Mandatory = $false)] [string] $Name,
        [parameter(Mandatory = $false)] [string] $AddressPrefix,
        [parameter(Mandatory = $false)] [string] $Gateway,
        [parameter(Mandatory = $false)] [string] $DNSServer,
        [HashTable][parameter(Mandatory=$false)] $AdditionalParams #  @ {"ICSFlags" = 0; }
    )

    Begin {
        if (!$JsonString) {
            $netobj = @{
                Type          = $Type;
            };

            if ($Name) {
                $netobj += @{
                    Name = $Name;
                }
            }

            if ($AddressPrefix -and  $Gateway) {
                $netobj += @{
                    Subnets = @(
                        @{
                            AddressPrefix  = $AddressPrefix;
                            GatewayAddress = $Gateway;
                        }
                    );
                }
            }

            if ($AdditionalParams) {
                $netobj += @{
                    AdditionalParams = @{}
                }

                foreach ($param in $AdditionalParams.Keys)
                {
                    $netobj.AdditionalParams += @{
                        $param = $AdditionalParams[$param];
                    }
                }
            }

            if ($DNSServerName) {
                
            }

            $JsonString = ConvertTo-Json $netobj -Depth 10
        }

    }
    Process{
        return Invoke-HNSRequest -Method POST -Type networks -Data $JsonString
    }
}

#########################################################################
# Endpoints
#########################################################################

function Get-HnsEndpointStats
{
    param
    (
        [parameter(Mandatory=$false)] [string] $Id = [Guid]::Empty
    )
    return Invoke-HNSRequest -Method GET -Type endpointstats -Id $id
}

function New-HnsEndpoint
{
    param
    (
        [parameter(Mandatory=$false, Position = 0)] [string] $JsonString = $null,
        [parameter(Mandatory = $false, Position = 0)] [Guid] $NetworkId,
        [parameter(Mandatory = $false)] [string] $Name,
        [parameter(Mandatory = $false)] [string] $IPAddress,
        [parameter(Mandatory = $false)] [string] $DNSServerList,
        [parameter(Mandatory = $false)] [string] $MacAddress,
        [parameter(Mandatory = $false)] [switch] $RemoteEndpoint,
        [parameter(Mandatory = $false)] [switch] $EnableOutboundNat,
        [HashTable][parameter(Mandatory=$false)] $InboundNatPolicy, #  @ {"InternalPort" = "80"; "ExternalPort" = "8080"}
        [HashTable][parameter(Mandatory=$false)] $PAPolicy #  @ {"PA" = "1.2.3.4"; }
    )

    begin
    {
        if ($JsonString)
        {
            $EndpointData = $JsonString | ConvertTo-Json | ConvertFrom-Json
        }
        else
        {
            $endpoint = @{
                VirtualNetwork = $NetworkId;
                Policies       = @();
            }

            if ($Name) {
                $endpoint += @{
                    Name = $Name;
                }
            }

            if ($MacAddress) {
                $endpoint += @{
                    MacAddress     = $MacAddress;
                }
            }

            if ($IPAddress) {
                $endpoint += @{
                    IPAddress      = $IPAddress;
                }
            }

            if ($DNSServerList) {
                $endpoint += @{
                    DNSServerList      = $DNSServerList;
                }
            }
            if ($RemoteEndpoint.IsPresent) {
                $endpoint += @{
                    IsRemoteEndpoint      = $true;
                }
            }

            if ($EnableOutboundNat.IsPresent) {
                $endpoint.Policies += @{
                    Type = "OutBoundNAT";
                }
            }

            if ($InboundNatPolicy) {
                $endpoint.Policies += @{
                        Type = "NAT";
                        InternalPort = $InboundNatPolicy["InternalPort"];
                        ExternalPort = $InboundNatPolicy["ExternalPort"];
                }
            }

            if ($PAPolicy) {
                $endpoint.Policies += @{
                        Type = "PA";
                        PA = $PAPolicy["PA"];
                }
            }

            # Try to Generate the data
            $EndpointData = convertto-json $endpoint
        }
    }

    Process
    {
        return Invoke-HNSRequest -Method POST -Type endpoints -Data $EndpointData
    }
}


function New-HnsRemoteEndpoint
{
    param
    (
        [parameter(Mandatory = $true)] [Guid] $NetworkId,
        [parameter(Mandatory = $false)] [string] $IPAddress,
        [parameter(Mandatory = $false)] [string] $MacAddress,
        [parameter(Mandatory = $false)] [string] $DNSServerList
    )

    $remoteEndpoint = New-HnsEndpoint -NetworkId $NetworkId -IPAddress $IPAddress -MacAddress $MacAddress -DNSServerList $DNSServerList -IsRemoteEndpoint
    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $remoteEndpoint  -Depth 10)
}


function Attach-HnsHostEndpoint
{
    param
    (
     [parameter(Mandatory=$true)] [Guid] $EndpointID,
     [parameter(Mandatory=$true)] [int] $CompartmentID
     )
    $request = @{
        SystemType    = "Host";
        CompartmentId = $CompartmentID;
    };

    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $request) -Action "attach" -Id $EndpointID
}

function Attach-HnsVMEndpoint
{
    param
    (
     [parameter(Mandatory=$true)] [Guid] $EndpointID,
     [parameter(Mandatory=$true)] [string] $VMNetworkAdapterName
     )

    $request = @{
        VirtualNicName   = $VMNetworkAdapterName;
        SystemType    = "VirtualMachine";
    };
    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $request ) -Action "attach" -Id $EndpointID

}

function Attach-HnsEndpoint
{
    param
    (
        [parameter(Mandatory=$true)] [Guid] $EndpointID,
        [parameter(Mandatory=$true)] [int] $CompartmentID,
        [parameter(Mandatory=$true)] [string] $ContainerID
    )
     $request = @{
        ContainerId = $ContainerID;
        SystemType="Container";
        CompartmentId = $CompartmentID;
    };

    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $request) -Action "attach" -Id $EndpointID
}

function Detach-HnsVMEndpoint
{
    param
    (
        [parameter(Mandatory=$true)] [Guid] $EndpointID
    )
    $request = @{
        SystemType  = "VirtualMachine";
    };

    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $request ) -Action "detach" -Id $EndpointID
}

function Detach-HnsHostEndpoint
{
    param
    (
        [parameter(Mandatory=$true)] [Guid] $EndpointID
    )
    $request = @{
        SystemType  = "Host";
    };

    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $request ) -Action "detach" -Id $EndpointID
}

function Detach-HnsEndpoint
{
    param
    (
        [parameter(Mandatory=$true)] [Guid] $EndpointID,
        [parameter(Mandatory=$true)] [string] $ContainerID
    )

    $request = @{
        ContainerId = $ContainerID;
        SystemType="Container";
    };

    return Invoke-HNSRequest -Method POST -Type endpoints -Data (ConvertTo-Json $request ) -Action "detach" -Id $EndpointID
}
#########################################################################

function Invoke-HnsRequest
{
    param
    (
        [ValidateSet('GET', 'POST', 'DELETE')]
        [parameter(Mandatory=$true)] [string] $Method,
        [ValidateSet('networks', 'endpoints', 'activities', 'policylists', 'endpointstats', 'plugins', 'compartments')]
        [parameter(Mandatory=$true)] [string] $Type,
        [parameter(Mandatory=$false)] [string] $Action = $null,
        [parameter(Mandatory=$false)] [string] $Data = $null,
        [parameter(Mandatory=$false)] [Guid] $Id = [Guid]::Empty
    )

    $hnsPath = "/$Type"

    if ($id -ne [Guid]::Empty)
    {
        $hnsPath += "/$id";
    }

    if ($Action)
    {
        $hnsPath += "/$Action";
    }

    $request = "";
    if ($Data)
    {
        $request = $Data
    }

    $output = "";
    $response = "";
    Write-Verbose "Invoke-HNSRequest Method[$Method] Path[$hnsPath] Data[$request]"

    $hnsApi = Get-VmComputeNativeMethods
    $hnsApi::HNSCall($Method, $hnsPath, "$request", [ref] $response);

    Write-Verbose "Result : $response"
    if ($response)
    {
        try {
            $output = ($response | ConvertFrom-Json);
        } catch {
            Write-Error $_.Exception.Message
            return ""
        }
        if ($output.Error)
        {
             Write-Error $output;
        }
        $output = $output.Output;
    }

    return $output;
}

#########################################################################

Export-ModuleMember -Function Get-HnsActivities
Export-ModuleMember -Function Get-HnsSwitchExtensions
Export-ModuleMember -Function Set-HnsSwitchExtension

Export-ModuleMember -Function Get-HnsEndpointStats

Export-ModuleMember -Function New-HnsNetwork
Export-ModuleMember -Function New-HnsEndpoint
Export-ModuleMember -Function New-HnsRemoteEndpoint
Export-ModuleMember -Function New-HnsProxyPolicy

Export-ModuleMember -Function Remove-HnsProxyPolicy

Export-ModuleMember -Function Attach-HnsHostEndpoint
Export-ModuleMember -Function Attach-HnsVMEndpoint
Export-ModuleMember -Function Attach-HnsEndpoint
Export-ModuleMember -Function Detach-HnsHostEndpoint
Export-ModuleMember -Function Detach-HnsVMEndpoint
Export-ModuleMember -Function Detach-HnsEndpoint


Export-ModuleMember -Function Get-HnsCompartment
Export-ModuleMember -Function New-HnsRoute
Export-ModuleMember -Function New-HnsLoadBalancer

Export-ModuleMember -Function Invoke-HnsRequest
