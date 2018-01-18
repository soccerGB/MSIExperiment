package main

import (
    "encoding/json"
    "io"
    "os/exec"
    "log"
    "net/http"
    "fmt"
    "strings"
)

const ( 
    ClientContainer  = "clientcontainer"
    ProxyContainer   = "proxycontainer"
    OtherContainer   = "othercontainer"
)

type Event struct {
    Id     string `json:"id"`
    Status string `json:"status"`
}

type Config struct {
    Hostname string
    Labels  map[string]string
}

// definition for NetworkSettings
type NAT struct {
    IPAddress string
}

type NetworksType struct {
    Nat *NAT
}

type NetworkSettings struct {
    //IpAddress   string
    SandboxID   string
    Networks    *NetworksType
    PortMapping map[string]map[string]string
}

// definition for Container
type Container struct {
    Id              string
    Name            string
    Image           string
    Config          *Config
    NetworkSettings *NetworkSettings
    ContainerType   string
}

func inspectContainer(id string, c http.Client) *Container {
    
     // Use the container id to fetch the container json from the Remote API
    // http://docs.docker.io/en/latest/api/docker_remote_api_v1.4/#inspect-a-container
    res, err := c.Get("http://localhost:2375/containers/" + id + "/json")
    if err != nil {
        log.Println(err)
        return nil
    }
    defer res.Body.Close()
   
    if res.StatusCode == http.StatusOK {
        d := json.NewDecoder(res.Body)

        var container Container
        if err = d.Decode(&container); err != nil {
            log.Fatal(err)
        }
        return &container
    }
    return nil
}

func notify(container *Container) {
    container.ContainerType = OtherContainer
    fmt.Println("\tName: ", container.Name) 
    fmt.Println("\tid: ", container.Id)
    fmt.Print("\tLabels: ")
    for key, value := range container.Config.Labels {
        if (strings.Compare( strings.ToLower(key), strings.ToLower(ClientContainer))==0) {
            container.ContainerType = ClientContainer
        } else if (strings.Compare( strings.ToLower(key), strings.ToLower(ProxyContainer))==0) {
            container.ContainerType = ProxyContainer
        }
        fmt.Print( key, "=", value, " ")
    }
    fmt.Println() 

    fmt.Println("\tIPAddress = ", 
        container.NetworkSettings.Networks.Nat.IPAddress)

    settings := container.NetworkSettings

    if settings != nil && settings.PortMapping != nil {
        // I only care about Tcp ports but you can also view Udp mappings
        if ports, ok := settings.PortMapping["Tcp"]; ok {

            log.Printf("Ip address allocated for: %s", container.Id)

            // Log the public and private port mappings
            for privatePort, publicPort := range ports {
                // I am just writing to stdout but you can use this information to update hipache, redis, etc...
                log.Printf("%s -> %s", privatePort, publicPort)
            }
        }
    }
}

func main() {
    fmt.Println("Monitoring Docker container events")

    // test running powershell
    out, err := exec.Command("powershell", ".\\test.ps1").Output()
    test := string(out[:])
    fmt.Println("out = %s", test)

    c := http.Client{}
    res, err := c.Get("http://localhost:2375/events")
  
    if err != nil {
        log.Fatal(err)
    }
    defer res.Body.Close()

    // Read the streaming json from the events endpoint
    // http://docs.docker.io/en/latest/api/docker_remote_api_v1.3/#monitor-docker-s-events
    d := json.NewDecoder(res.Body)
    for {
        var event Event
        if err := d.Decode(&event); err != nil {
            if err == io.EOF {
                break
            }
            log.Fatal(err)
        }
        fmt.Println("Docker event received: event.Status = ", event.Status)
        if event.Status == "start" {
            fmt.Println("A container is started")
            // We only want to inspect the container if it has started
            if container := inspectContainer(event.Id, c); container != nil {
                notify(container)
                fmt.Println("ContainerType is ", container.ContainerType)
            }
        } else if event.Status == "die" {
            fmt.Println("a container is stopped %", event.Id)
        }
    }
}