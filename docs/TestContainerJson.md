# Json file for ProxyContainer container job
      { 
        "id": "1", 
        "cmd": null, 
        "cpus": 1, 
        "mem": 512, 
        "disk": 0, 
        "instances": 1, 
        "container": { 
            "type": "DOCKER", 
            "volumes": [], 
            "docker": { 
                "image": "msitest/test:proxycontainer", 
                "privileged": false, 
                "parameters": [ 
                { 
                "key": "network", 
                "value": "nat" 
                },
                      {
                        "key": "label",
                        "value": "MSIProxyContainer"
                      }
                ], 
                "forcePullImage": false 
            } 
        } 
    } 
    
    # Json file for ClientContainer container job
    
      { 
        "id": "2", 
        "cmd": null, 
        "cpus": 1, 
        "mem": 128, 
        "disk": 0, 
        "instances": 1, 
        "container": { 
            "type": "DOCKER", 
            "volumes": [], 
            "docker": { 
                "image": "msitest/test:clientcontainer", 
                "privileged": false, 
                "parameters": [ 
                { 
                "key": "network", 
                "value": "nat" 
                },
                      {
                        "key": "env",
                        "value": "IMSProxyIpAddress"
                      }
                ], 
                "forcePullImage": false 
            } 
        } 
    } 
