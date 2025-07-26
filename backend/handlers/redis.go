package handlers

import (
	"context"

	"github.com/ameysunu/cloudstroll/config"
	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()
var redisClient *redis.Client

func ConnectToRedis() {

	redisClient = redis.NewClient(&redis.Options{
		Addr:     config.GetEnv("REDIS_HOST", ""),
		Username: config.GetEnv("REDIS_USERNAME", ""),
		Password: config.GetEnv("REDIS_PASSWORD", ""),
		DB:       0,
	})

}
