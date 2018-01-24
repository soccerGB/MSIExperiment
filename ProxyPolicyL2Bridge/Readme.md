

# Proxy policy solution (prototyping in progress)

# How it works
Basically, this approach handles all the network setup outside of the Docker control.
1.	Setup a L2Bridge hnsNetwork 
    - Create a hnsNetowork 
    - Create a gateway hnsEndpoint off above L2bridge network and bind it into the host networking compartment (1) before enabling its ip forwarding
2.	Launch the proxycontainer and create a hnsEndpoint before attaching it to the container instance’s corresponding compartment
3.	Locate the ip address of the proxycontainer  (proxycontainer _ip)
4.	Launch a clientcontainer and create a hnsEndpoint before attaching it to the container instance’s corresponding compartment
5.	Setup a proxy policy on clientcontainer’s hsnEndpoint
    -   Locate a clientcontainer’s hsnEndpoint id
    -   Create a proxy policy
New-HnsProxyPolicy -Destination "proxycontainer _ip" -OutboundNat $true -DestinationPrefix 169.254.169.254 -DestinationPort 80  -Endpoints hsnEndpointId

- Pros:
  -	L2Bridge should be more efficient than Nat mode
  -	No need to add any logics into the client container
  -	This is the same mode used by the Kubernetes cluster
  -	With this CNI like approach (handling all the network outside of Docker), this could be a good solution when we move to DC/OS Mesos’ Universal Container Runtime model (we could hide all those details inside an isolation, or better yet we could wrap the CNI plug-in into it)
  
- Cons:
  -	Proxy policy does not support NAT mode 
  -	Still requires some operations  outside of container payload
  -	Only available on RS4 or later
  -	Does not fit well into DC/OS Mesos’s Docker Containerizer model, which is a thin wrapper around the native Docker CLI command




