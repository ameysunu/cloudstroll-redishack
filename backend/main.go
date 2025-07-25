package main

import (
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
	r := mux.NewRouter()

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello, and welcome to Cloud Stroll's backend, built with Go by Amey")
	})

	// Start the HTTP server
	http.Handle("/", r)
	fmt.Println("Server is running on port 8080")
	http.ListenAndServe(":8080", nil)
}
