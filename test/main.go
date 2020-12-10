package main

import "net/http"

func main() {
	http.Handle("/", http.FileServer(http.Dir("/home/yttx_heqian/develop/flutter/yttx/heqian_flutter_utils/example/build/web")))
	http.ListenAndServe("0.0.0.0:8080", nil)
}
