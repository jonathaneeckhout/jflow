package main

import (
	"log"

	"github.com/jonathaneeckhout/jflow/api"
	"github.com/jonathaneeckhout/jflow/jobs"
)

func main() {
	addr := "localhost:8080"
	dbPath := "./users.db"
	jwtKey := "supersecretkey"

	if err := jobs.Start(); err != nil {
		log.Fatal(err)
	}

	if err := api.Start(addr, dbPath, jwtKey); err != nil {
		log.Fatal(err)
	}
}
