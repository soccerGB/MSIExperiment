package main

import (
  "flag"
  "fmt"
  "net/http"
  "net/http/httputil"
  "net/url"
)

var (
	proxyip string
)
const (
	defaultTarget           = "http://127.0.0.1:80"
	defaultTargetUsage      = "main -proxyip http://172.19.201.94:80"
	MSI_HOST = "169.254.169.254"
	MSI_PORT = "80"
	MSI_ADDRESS = "169.254.169.254:80"
	PROTOCOL_TYPE = "tcp"
)

type Prox struct {
  target        *url.URL
  proxy         *httputil.ReverseProxy
}

func New(target string) *Prox {
  url, _ := url.Parse(target)

  return &Prox{target: url,proxy: httputil.NewSingleHostReverseProxy(url)}
}

func (p *Prox) handle(w http.ResponseWriter, r *http.Request) {
	fmt.Println("handle() called\n")
  	w.Header().Set("X-GoProxy", "GoProxy")

	// call to magic method from ReverseProxy object
	p.proxy.ServeHTTP(w, r)
}

func init() {
	fmt.Println("init() called")
	flag.StringVar(&proxyip, "proxyip", "", "the target (<host>:<port>)")
	fmt.Println("proxyip is ",proxyip)
}

func main() {

	fmt.Println("Utiltiy container is running!")

	// flags
	flag.Parse()

	fmt.Println("server will run on : %v:%v\n", MSI_HOST, MSI_PORT)
	fmt.Println("redirecting to :", proxyip)

	backendServiceIpPort := "http://" + proxyip
	fmt.Println("backendServiceIpPort :%s\n", backendServiceIpPort)

	// proxy
        proxy := New(backendServiceIpPort)

	fmt.Println("Waiting for new connection request:\n")
	// server
	http.HandleFunc("/", proxy.handle)
	http.ListenAndServe(MSI_ADDRESS, nil)
}