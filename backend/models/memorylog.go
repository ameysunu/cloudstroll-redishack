package models

type MemoryLog struct {
	Location  string    `json:"location"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Entry     string    `json:"entry"`
	Mood      string    `json:"mood"`
	Weather   string    `json:"weather"`
	Timestamp string    `json:"timestamp"`
	Embedding []float64 `json:"embedding"`
}
