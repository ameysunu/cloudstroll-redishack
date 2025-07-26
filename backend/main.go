package main

import (
	"fmt"
	"net/http"

	"github.com/ameysunu/cloudstroll/config"
	"github.com/ameysunu/cloudstroll/handlers"
	"github.com/gorilla/mux"
)

func main() {
	config.LoadEnv()
	handlers.ConnectToRedis()

	r := mux.NewRouter()

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello, and welcome to Cloud Stroll's backend, built with Go by Amey")
	})

	//Only for testing Redis connection

	r.HandleFunc("/connect-redis", func(w http.ResponseWriter, r *http.Request) {
		handlers.ConnectToRedis()
		fmt.Fprintln(w, "Connected to Redis and set a key-value pair")
	}).Methods("GET")

	r.HandleFunc("/memory", handlers.CreateMemory).Methods("POST")

	// Start the HTTP server
	http.Handle("/", r)
	fmt.Println("Server is running on port 8080")
	http.ListenAndServe(":8080", nil)
}
