package handlers

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	"github.com/ameysunu/cloudstroll/config"
)

func embedText(text string) ([]float32, error) {
	payload := map[string][]string{"inputs": {text}}
	body, _ := json.Marshal(payload)

	const hfRouterURL = "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/feature-extraction"

	req, err := http.NewRequest("POST", hfRouterURL, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+config.GetEnv("HUGGINGFACE_API_TOKEN", ""))
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("HF error: %s", resp.Status)
	}
	// HF returns [[…]] — a slice of embeddings
	var outer [][]float32
	if err := json.NewDecoder(resp.Body).Decode(&outer); err != nil {
		return nil, err
	}
	if len(outer) == 0 {
		return nil, errors.New("no embedding returned")
	}
	return outer[0], nil
}
