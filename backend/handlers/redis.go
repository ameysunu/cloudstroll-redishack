package handlers

import (
	"context"
	"fmt"

	"github.com/ameysunu/cloudstroll/config"
	"github.com/redis/go-redis/v9"
)

func ConnectToRedis() {
	ctx := context.Background()

	rdb := redis.NewClient(&redis.Options{
		Addr:     config.GetEnv("REDIS_HOST", ""),
		Username: config.GetEnv("REDIS_USERNAME", ""),
		Password: config.GetEnv("REDIS_PASSWORD", ""),
		DB:       0,
	})

	rdb.Set(ctx, "foo", "bar", 0)
	result, err := rdb.Get(ctx, "foo").Result()

	if err != nil {
		panic(err)
	}

	fmt.Println(result)

}
