1. Test mesos fetcher 
  Schedule a non-container task from DC/OS and fetch some file in preparation execution
  Start with local file first
  file://c:/temp/
  run agent scope level operation
  
  
      Done:
        Validated that I was able to schedule a non-container service to locate the proxycontainer's ip addess for setting global environment variable, which is available to another non-container dcos service

  
 2. Write a MSI helper app 
   monitor docker container life cycle with appropriate labels
   get IP addressed for the proxycontainer and client containers
   setup proxypolicy on the hnsendpoint for each client container
   
   
3. Try ProxyPolicy on RS4 build in a Azure Vm environment

4. DC/OS cluster with RS4 windows agent
   
    
