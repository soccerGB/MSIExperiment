Experiments on the redirecting Instance Metadata Service requests from Docker containers to a external facing proxy Docker container
This experiment was to find a way to access Azure's Instance Metadata Service endpoint (http:// 169.254.169.254) from client containers through a dedicated proxy container. My experiment belows show, with appropriate port fordwarding and routing setup, it's possible to achieve above scenario inside a Azure VM running a WindowsServerCore:1709 (RS3) build.

Block diagram for Proxying Instance Metadata Service request

(Note: in this setup, all containers are in the same subset)
