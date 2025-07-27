package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/ameysunu/cloudstroll/models"
	"github.com/google/uuid"
)

func CreateMemory(w http.ResponseWriter, r *http.Request) {

	if RedisClient == nil {
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

	result := RedisClient.Do(Ctx, "JSON.SET", redisKey, "$", jsonBytes)
	if result.Err() != nil {
		http.Error(w, "Failed to save to Redis", http.StatusInternalServerError)
		return
	}

	geoKey := "memory:geo"
	_, err = RedisClient.Do(Ctx,
		"GEOADD", geoKey,
		mem.Longitude, mem.Latitude,
		redisKey, // same key you used for JSON.SET
	).Result()
	if err != nil {
		http.Error(w, "Failed to add geo data: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "Memory saved with ID %s\n", id)
}

func SearchMemories(w http.ResponseWriter, r *http.Request) {
	mood := r.URL.Query().Get("mood")
	query := r.URL.Query().Get("query")

	// Build the query string
	parts := []string{}
	if mood != "" {
		parts = append(parts, fmt.Sprintf("@mood:{%s}", mood))
	}
	if query != "" {
		parts = append(parts, fmt.Sprintf("@entry:%s", query))
	}
	searchQuery := "*"
	if len(parts) > 0 {
		searchQuery = strings.Join(parts, " ")
	}

	// Fire FT.SEARCH
	cmd := RedisClient.Do(Ctx,
		"FT.SEARCH", "memory-idx", searchQuery,
		"LIMIT", "0", "100",
		"RETURN", "1", "$",
	)
	res, err := cmd.Result()
	if err != nil {
		http.Error(w, "Redis search error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Prepare our result slice (non‑nil so it encodes as [])
	matches := make([]map[string]interface{}, 0)

	// Helper: pull the JSON string out of any map shape
	extractJSON := func(raw interface{}) string {
		// raw should be a map[string]interface{} or map[interface{}]interface{}
		var msi map[string]interface{}

		switch m := raw.(type) {
		case map[string]interface{}:
			msi = m
		case map[interface{}]interface{}:
			msi = make(map[string]interface{}, len(m))
			for k, v := range m {
				if ks, ok := k.(string); ok {
					msi[ks] = v
				}
			}
		default:
			return ""
		}

		// 1) extra_attributes.$
		if ea, ok := msi["extra_attributes"]; ok {
			switch eav := ea.(type) {
			case map[string]interface{}:
				if s, ok := eav["$"].(string); ok {
					return s
				}
			case map[interface{}]interface{}:
				for k, v := range eav {
					if ks, ok := k.(string); ok && ks == "$" {
						if s, ok2 := v.(string); ok2 {
							return s
						}
					}
				}
			}
		}

		// 2) values = [key, json]
		if vals, ok := msi["values"].([]interface{}); ok && len(vals) >= 2 {
			if s, ok2 := vals[1].(string); ok2 {
				return s
			}
		}

		// 3) direct "$"
		if s, ok := msi["$"].(string); ok {
			return s
		}
		return ""
	}

	// 1) If res is CLI‑style []interface{}
	if arr, ok := res.([]interface{}); ok {
		for i := 1; i < len(arr); i += 2 {
			raw := arr[i+1]
			jsonStr := extractJSON(raw)
			if jsonStr == "" {
				continue
			}
			var obj map[string]interface{}
			if err := json.Unmarshal([]byte(jsonStr), &obj); err == nil {
				matches = append(matches, obj)
			}
		}

	} else {
		// 2) If res is a map at top level
		var top map[string]interface{}

		switch t := res.(type) {
		case map[string]interface{}:
			top = t
		case map[interface{}]interface{}:
			top = make(map[string]interface{}, len(t))
			for k, v := range t {
				if ks, ok := k.(string); ok {
					top[ks] = v
				}
			}
		default:
			http.Error(w, fmt.Sprintf("Unexpected Redis result type: %T", res), http.StatusInternalServerError)
			return
		}

		// Grab the "results" array
		rawResults, ok := top["results"]
		if !ok {
			// no matches -> return empty array
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(matches)
			return
		}

		if items, ok := rawResults.([]interface{}); ok {
			for _, item := range items {
				jsonStr := extractJSON(item)
				if jsonStr == "" {
					continue
				}
				var obj map[string]interface{}
				if err := json.Unmarshal([]byte(jsonStr), &obj); err == nil {
					matches = append(matches, obj)
				}
			}
		}
	}

	// Return JSON array (could be empty)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(matches)
}
