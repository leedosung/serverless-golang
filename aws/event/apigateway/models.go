package apigateway

import "encoding/json"

type APIGatewayResponse struct {
	StatusCode    int                 `json:"statusCode"`
	Headers       map[string]string   `json:"headers"`
	Body          interface{}         `json:"body"`
	Base64Encoded bool                `json:"isBase64Encoded"`
}

func NewAPIGatewayResponse(status int) *APIGatewayResponse {
	return &APIGatewayResponse{
		StatusCode:    status,
		Base64Encoded: false,
		Headers:       make(map[string]string),
	}
}

// inspired by serverless-java
func (r *APIGatewayResponse) SetBody(b interface{}) {
	bytes, _ := json.Marshal(b)
	r.Body = string(bytes)
}
