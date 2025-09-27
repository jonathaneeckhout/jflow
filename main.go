package main

import (
	"log"

	"github.com/jonathaneeckhout/jflow/api"
)

func main() {
	addr := "localhost:8080"
	dbPath := "./users.db"
	jwtKey := "supersecretkey"

	if err := api.Start(addr, dbPath, jwtKey); err != nil {
		log.Fatal(err)
	}
}
