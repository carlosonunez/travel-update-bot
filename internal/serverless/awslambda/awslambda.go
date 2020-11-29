package awslambda

import (
	"encoding/json"
)

type awsLambdaResponse struct {
	StatusCode int         `json:"statusCode"`
	Body       interface{} `json:"body"`
}

type empty struct{}

// Ok returns a 200 OK response with an optional body.
func Ok(v ...interface{}) string {
	var b interface{}
	if len(v) > 0 {
		b = v[0]
	} else {
		b = empty{}
	}
	resp := awsLambdaResponse{
		StatusCode: 200,
		Body:       &b,
	}
	return respToJSON(&resp)
}

// Error returns an error with a HTTP 422 repsonse code (because Lambda
// eats HTTP 400 Bad Requests.
func Error(s string) string {
	type err struct {
		Message string `json:"error"`
	}
	resp := awsLambdaResponse{
		StatusCode: 422,
		Body:       err{Message: s},
	}
	return respToJSON(&resp)
}

func respToJSON(r *awsLambdaResponse) string {
	j, err := json.Marshal(&r)
	if err != nil {
		panic(err)
	}
	return string(j)
}
