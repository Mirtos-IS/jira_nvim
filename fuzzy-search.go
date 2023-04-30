package main

import (
	"bytes"
	"io/ioutil"
	"log"
	"net/http"
)
func requestSearchQueryJira(query string) ([]byte, error) {
    client := &http.Client{
        CheckRedirect: redirectPolicyFunc,
    }

    baseURL := "https://turnoverbnb.atlassian.net/rest/api/3/issue/picker?query="

    byteQuery := []byte(query)
    bodyQuery := bytes.NewReader(byteQuery)
    request, err := http.NewRequest("GET", baseURL, bodyQuery)

    request.Header.Set("Accept", "application/json")
    request.SetBasicAuth(token.User, token.Token)

    resp, err := client.Do(request)
    if err != nil {
        return nil, err
    }
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        log.Fatalln(err)
        return nil, err
    }
    // fmt.Printf(string(body))
    return body, nil
}
