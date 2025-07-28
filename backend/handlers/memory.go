package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/ameysunu/cloudstroll/models"
	"github.com/google/uuid"
)

func CreateMemory(w http.ResponseWriter, r *http.Request) {
	if RedisClient == nil {
		http.Error(w, "Redis not initialized", http.StatusInternalServerError)
		return
	}

	var mem models.MemoryLog
	if err := json.NewDecoder(r.Body).Decode(&mem); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	ts, err := time.Parse(time.RFC3339, mem.Timestamp)
	if err != nil {
		http.Error(w, "Invalid timestamp format. Use RFC3339 (e.g., 2025-07-27T12:00:00Z)", http.StatusBadRequest)
		return
	}
	// Convert to milliseconds for Redis TimeSeries
	tsMs := ts.UnixNano() / 1e6

	id := uuid.New().String()
	key := fmt.Sprintf("memory:%s", id)
	raw, _ := json.Marshal(mem)
	if err := RedisClient.Do(Ctx, "JSON.SET", key, "$", raw).Err(); err != nil {
		http.Error(w, "Failed to save JSON: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if _, err := RedisClient.Do(Ctx,
		"GEOADD", "memory:geo",
		mem.Longitude, mem.Latitude,
		key,
	).Result(); err != nil {
		http.Error(w, "Failed GEOADD: "+err.Error(), http.StatusInternalServerError)
		return
	}

	seriesKey := fmt.Sprintf("mood:trend:%s", mem.Mood)

	_, err = RedisClient.Do(Ctx,
		"TS.CREATE", seriesKey,
		"RETENTION", "0",
		"LABELS", "mood", mem.Mood,
	).Result()
	if err != nil && !strings.Contains(err.Error(), "already exists") {
		http.Error(w, "TS.CREATE error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if _, err := RedisClient.Do(Ctx,
		"TS.ADD", seriesKey,
		tsMs, // Use the timestamp from the payload
		1,
	).Result(); err != nil {
		http.Error(w, "TS.ADD error: "+err.Error(), http.StatusInternalServerError)
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
