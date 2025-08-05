package handlers

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"strings"
	"time"

	"github.com/ameysunu/cloudstroll/models"
	"github.com/google/uuid"
)

func CreateMemory(w http.ResponseWriter, r *http.Request) {
	if RedisClient == nil {
		log.Println("Error: RedisClient is not initialized")
		http.Error(w, "Redis not initialized", http.StatusInternalServerError)
		return
	}

	var mem models.MemoryLog
	if err := json.NewDecoder(r.Body).Decode(&mem); err != nil {
		log.Printf("Error decoding JSON payload: %v", err)
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Assign IDs & log payload
	newID := uuid.New()
	mem.Id = newID
	pretty, _ := json.MarshalIndent(mem, "", "  ")
	log.Printf("Received JSON payload:\n%s", string(pretty))

	// Parse timestamp
	ts, err := time.Parse(time.RFC3339, mem.Timestamp)
	if err != nil {
		log.Printf("Error parsing timestamp '%s': %v", mem.Timestamp, err)
		http.Error(w, "Invalid timestamp format. Use RFC3339", http.StatusBadRequest)
		return
	}
	tsMs := ts.UnixNano() / 1e6

	emb, err := embedText(mem.Entry)
	if err != nil {
		log.Printf("Embedding error: %v", err)
		http.Error(w, "Embedding error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	mem.Embedding = make([]float64, len(emb))
	for i, v := range emb {
		mem.Embedding[i] = float64(v)
	}

	id := uuid.New().String()
	key := fmt.Sprintf("memory:%s", id)
	raw, _ := json.Marshal(mem)
	if err := RedisClient.Do(Ctx, "JSON.SET", key, "$", raw).Err(); err != nil {
		log.Printf("Error saving JSON to Redis for key '%s': %v", key, err)
		http.Error(w, "Failed to save JSON: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if _, err := RedisClient.Do(Ctx,
		"GEOADD", "memory:geo",
		mem.Longitude, mem.Latitude,
		key,
	).Result(); err != nil {
		log.Printf("Error performing GEOADD for key '%s': %v", key, err)
		http.Error(w, "Failed GEOADD: "+err.Error(), http.StatusInternalServerError)
		return
	}

	seriesKey := fmt.Sprintf("mood:trend:%s", mem.Mood)
	if _, err := RedisClient.Do(Ctx,
		"TS.CREATE", seriesKey,
		"RETENTION", "0",
		"LABELS", "mood", mem.Mood,
	).Result(); err != nil && !strings.Contains(err.Error(), "already exists") {
		log.Printf("Error creating time series '%s': %v", seriesKey, err)
		http.Error(w, "TS.CREATE error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	if _, err := RedisClient.Do(Ctx,
		"TS.ADD", seriesKey,
		tsMs,
		1,
	).Result(); err != nil {
		log.Printf("Error adding to time series '%s': %v", seriesKey, err)
		http.Error(w, "TS.ADD error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	log.Printf("Successfully saved memory with ID %s", id)
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

func SearchMemoriesByUid(w http.ResponseWriter, r *http.Request) {
	uid := r.URL.Query().Get("uid")
	if uid == "" {
		http.Error(w, "Missing 'uid' query parameter", http.StatusBadRequest)
		return
	}

	escapedUID := strings.ReplaceAll(uid, "-", "\\-")
	searchQuery := fmt.Sprintf("@uid:{%s}", escapedUID)

	cmd := RedisClient.Do(Ctx,
		"FT.SEARCH", "memory-idx", searchQuery,
		"LIMIT", "0", "1000",
		"RETURN", "1", "$",
	)
	res, err := cmd.Result()
	if err != nil {
		http.Error(w, "Redis search error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	matches := make([]models.MemoryLog, 0)
	if resultMap, ok := res.(map[interface{}]interface{}); ok {
		if rawResults, ok := resultMap["results"].([]interface{}); ok {
			for _, resultItem := range rawResults {
				if itemMap, ok := resultItem.(map[interface{}]interface{}); ok {
					if extraAttrs, ok := itemMap["extra_attributes"].(map[interface{}]interface{}); ok {
						if jsonStr, ok := extraAttrs["$"].(string); ok {
							var mem models.MemoryLog
							if err := json.Unmarshal([]byte(jsonStr), &mem); err == nil {
								matches = append(matches, mem)
							}
						}
					}
				}
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(matches); err != nil {
		http.Error(w, "Failed to encode response: "+err.Error(), http.StatusInternalServerError)
	}
}

func SearchSemantic(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q == "" {
		http.Error(w, "Query `q` required", http.StatusBadRequest)
		return
	}
	topk := r.URL.Query().Get("topk")
	if topk == "" {
		topk = "5"
	}

	emb32, err := embedText(q)
	if err != nil {
		http.Error(w, "Embedding error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	blob := float32SliceToBlob(emb32)

	query := fmt.Sprintf("* => [KNN %s @vec $BLOB]", topk)
	res, err := RedisClient.Do(Ctx,
		"FT.SEARCH", "memory-idx",
		query,
		"DIALECT", "2",
		"PARAMS", "2", "BLOB", blob,
		"RETURN", "1", "$",
		"LIMIT", "0", topk,
	).Result()
	if err != nil {
		http.Error(w, "Redis search error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var matches []map[string]interface{}

	if arr, ok := res.([]interface{}); ok {
		for i := 1; i < len(arr); i += 2 {
			rec, ok := arr[i+1].([]interface{})
			if !ok || len(rec) == 0 {
				continue
			}
			jsonStr, _ := rec[0].(string)
			var obj map[string]interface{}
			if err := json.Unmarshal([]byte(jsonStr), &obj); err == nil {
				matches = append(matches, obj)
			}
		}
	}
	if mp, ok := res.(map[interface{}]interface{}); ok {
		if rawResults, exists := mp["results"].([]interface{}); exists {
			for _, item := range rawResults {
				itemMap, ok := item.(map[interface{}]interface{})
				if !ok {
					continue
				}

				if extras, ok := itemMap["extra_attributes"].(map[interface{}]interface{}); ok {
					if jsonStr, ok := extras["$"].(string); ok {
						var obj map[string]interface{}
						if err := json.Unmarshal([]byte(jsonStr), &obj); err == nil {
							matches = append(matches, obj)
						}
					}
				}
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(matches)
}

func float32SliceToBlob(vec []float32) []byte {
	buf := make([]byte, 4*len(vec))
	for i, v := range vec {
		bits := math.Float32bits(v)
		binary.LittleEndian.PutUint32(buf[i*4:], bits)
	}
	return buf
}
