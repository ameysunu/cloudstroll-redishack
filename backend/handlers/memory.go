package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/ameysunu/cloudstroll/models"
	"github.com/google/uuid"
)

func CreateMemory(w http.ResponseWriter, r *http.Request) {

	if redisClient == nil {
		http.Error(w, "Redis not initialized", http.StatusInternalServerError)
		return
	}

	var mem models.MemoryLog

	err := json.NewDecoder(r.Body).Decode(&mem)
	if err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	id := uuid.New().String()
	redisKey := fmt.Sprintf("memory:%s", id)

	jsonBytes, err := json.Marshal(mem)
	if err != nil {
		http.Error(w, "Error encoding data", http.StatusInternalServerError)
		return
	}

	result := redisClient.Do(ctx, "JSON.SET", redisKey, "$", jsonBytes)
	if result.Err() != nil {
		http.Error(w, "Failed to save to Redis", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "Memory saved with ID %s\n", id)
}
