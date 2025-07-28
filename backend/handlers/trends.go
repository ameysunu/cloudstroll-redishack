package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/ameysunu/cloudstroll/models"
)

func SearchMemoriesTrends(w http.ResponseWriter, r *http.Request) {
	const layout = "2006-01-02"
	fromStr := r.URL.Query().Get("from")
	toStr := r.URL.Query().Get("to")
	if fromStr == "" || toStr == "" {
		http.Error(w, "from and to required", http.StatusBadRequest)
		return
	}

	fromDate, err := time.Parse(layout, fromStr)
	if err != nil {
		http.Error(w, "invalid from date", http.StatusBadRequest)
		return
	}
	fromUTC := time.Date(fromDate.Year(), fromDate.Month(), fromDate.Day(),
		0, 0, 0, 0, time.UTC)
	fromMs := fromUTC.UnixNano() / 1e6

	toDate, err := time.Parse(layout, toStr)
	if err != nil {
		http.Error(w, "invalid to date", http.StatusBadRequest)
		return
	}
	toUTC := time.Date(toDate.Year(), toDate.Month(), toDate.Day(),
		23, 59, 59, 999000000, time.UTC)
	toMs := toUTC.UnixNano() / 1e6

	var seriesKeys []string
	cursor := "0"
	for {
		scanRes, err := RedisClient.Do(Ctx, "SCAN", cursor, "MATCH", "mood:trend:*").Result()
		if err != nil {
			http.Error(w, "scan error: "+err.Error(), http.StatusInternalServerError)
			return
		}
		arr, ok := scanRes.([]interface{})
		if !ok || len(arr) < 2 {
			break
		}
		cursor = fmt.Sprintf("%v", arr[0])
		keysSlice, ok := arr[1].([]interface{})
		if !ok {
			break
		}
		for _, k := range keysSlice {
			if ks, ok := k.(string); ok {
				seriesKeys = append(seriesKeys, ks)
			}
		}
		if cursor == "0" {
			break
		}
	}

	resp := make(map[string][]models.TrendPoint, len(seriesKeys))

	for _, key := range seriesKeys {
		parts := strings.Split(key, ":")
		mood := parts[len(parts)-1]

		trRaw, err := RedisClient.Do(Ctx,
			"TS.RANGE", key,
			strconv.FormatInt(fromMs, 10),
			strconv.FormatInt(toMs, 10),
		).Result()
		if err != nil {
			fmt.Printf("⚠️ TS.RANGE error on %s: %v\n", key, err)
			continue
		}

		rawPts, ok := trRaw.([]interface{})
		if !ok {
			continue
		}

		pts := make([]models.TrendPoint, 0, len(rawPts))
		for _, item := range rawPts {
			pair, ok := item.([]interface{})
			if !ok || len(pair) < 2 {
				continue
			}

			var tsInt int64
			switch t := pair[0].(type) {
			case int64:
				tsInt = t
			case string:
				tsInt, _ = strconv.ParseInt(t, 10, 64)
			}

			var valF float64
			switch v := pair[1].(type) {
			case string:
				valF, _ = strconv.ParseFloat(v, 64)
			case int64:
				valF = float64(v)
			case float64:
				valF = v
			default:
				continue
			}

			pts = append(pts, models.TrendPoint{Timestamp: tsInt, Value: valF})
		}

		resp[mood] = pts
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
