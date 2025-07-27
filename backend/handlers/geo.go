package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
)

// SearchMemoriesNear returns all memories within a given radius (km) of lat/lon.
func SearchMemoriesNear(w http.ResponseWriter, r *http.Request) {
	latStr := r.URL.Query().Get("lat")
	lonStr := r.URL.Query().Get("lon")
	radStr := r.URL.Query().Get("radius")
	if latStr == "" || lonStr == "" {
		http.Error(w, "lat and lon params required", http.StatusBadRequest)
		return
	}
	if radStr == "" {
		radStr = "5" // default radius in km
	}
	lat, err1 := strconv.ParseFloat(latStr, 64)
	lon, err2 := strconv.ParseFloat(lonStr, 64)
	rad, err3 := strconv.ParseFloat(radStr, 64)
	if err1 != nil || err2 != nil || err3 != nil {
		http.Error(w, "invalid lat, lon or radius", http.StatusBadRequest)
		return
	}

	raw, err := RedisClient.Do(Ctx,
		"GEOSEARCH", "memory:geo",
		"FROMLONLAT", lon, lat,
		"BYRADIUS", rad, "km",
		"WITHCOORD",
	).Result()
	if err != nil {
		http.Error(w, "Redis geo error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	rows, ok := raw.([]interface{})
	if !ok {
		http.Error(w, fmt.Sprintf("unexpected geo result type %T", raw), http.StatusInternalServerError)
		return
	}

	memories := make([]map[string]interface{}, 0, len(rows))

	for _, row := range rows {
		pair, ok := row.([]interface{})
		if !ok || len(pair) < 1 {
			continue
		}
		key, ok := pair[0].(string)
		if !ok {
			continue
		}

		rawVal, err := RedisClient.Do(Ctx, "JSON.GET", key).Result()
		if err != nil {
			fmt.Printf("JSON.GET error for %s: %v\n", key, err)
			continue
		}
		fmt.Printf("Raw JSON.GET data for %s: %#v\n", key, rawVal)

		var jsonStr string
		switch v := rawVal.(type) {
		case string:
			jsonStr = v
		case []interface{}:
			if len(v) > 0 {
				if s, ok := v[0].(string); ok {
					jsonStr = s
				}
			}
		default:
			fmt.Printf("⚠️ Unexpected JSON.GET type for %s: %T\n", key, rawVal)
			continue
		}
		if jsonStr == "" {
			continue
		}

		var entry map[string]interface{}
		if err := json.Unmarshal([]byte(jsonStr), &entry); err != nil {
			fmt.Printf("JSON unmarshal error for %s: %v\n", key, err)
			continue
		}
		memories = append(memories, entry)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(memories)
}
