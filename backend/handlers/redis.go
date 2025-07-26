package handlers

import (
	"context"

	"github.com/ameysunu/cloudstroll/config"
	"github.com/redis/go-redis/v9"
)

var Ctx = context.Background()
var RedisClient *redis.Client

func ConnectToRedis() {

	RedisClient = redis.NewClient(&redis.Options{
		Addr:     config.GetEnv("REDIS_HOST", ""),
		Username: config.GetEnv("REDIS_USERNAME", ""),
		Password: config.GetEnv("REDIS_PASSWORD", ""),
		DB:       0,
	})

}
