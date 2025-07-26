package scripts

import (
	"fmt"

	"github.com/ameysunu/cloudstroll/handlers"
)

func CreateRediSearchIndex() error {
	// Check if index already exists
	_, err := handlers.RedisClient.Do(handlers.Ctx, "FT.INFO", "memory-idx").Result()
	if err == nil {
		fmt.Println("RediSearch index already exists")
		return nil
	}

	fmt.Println("Creating RediSearch index...")

	cmd := handlers.RedisClient.Do(handlers.Ctx,
		"FT.CREATE", "memory-idx",
		"ON", "JSON",
		"PREFIX", "1", "memory:",
		"SCHEMA",
		"$.mood", "AS", "mood", "TAG",
		"$.entry", "AS", "entry", "TEXT",
	)

	if cmd.Err() != nil {
		return fmt.Errorf("failed to create RediSearch index: %v", cmd.Err())
	}

	fmt.Println("RediSearch index created")
	return nil
}
