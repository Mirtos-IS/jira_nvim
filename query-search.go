package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
)

type Search struct {
    Key string
    Link string
    Reporter string
    Assignee string
    Priority string
    Status string
    Summary string
    Title string
}

type QueryResult struct {
    Total int
    Issues []Issue
}

type Issue struct {
    Key string
    Link string `json:"self"`
    Fields SearchFields
}

type SearchFields struct {
    issueType map[string]any
    Project map[string]any
    Priority map[string]any
    Status map[string]any
    Reporter Creator
    Assignee Creator
    Summary string
}

func requestQueryJira(query string) ([]Search, error) {
    client := &http.Client{
        CheckRedirect: redirectPolicyFunc,
    }

    baseURL := "https://turnoverbnb.atlassian.net/rest/api/3/search?"
    url, _ := url.Parse(baseURL)
    queryUrl := url.Query()
    queryUrl.Set("jql", query)

    urlRaw := queryUrl.Encode()
    fullUrl := baseURL + urlRaw

    request, err := http.NewRequest("GET", fullUrl, nil)

    request.Header.Set("Accept", "application/json")
    request.SetBasicAuth(token.User, token.Token)

    resp, err := client.Do(request)
    if err != nil {
        fmt.Println(err)
        return nil, err
    }
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        log.Fatalln(err)
        fmt.Println(err)
        return nil, err
    }
    searches := parseQuerySearches(body)
    return searches, nil
}

func parseQuerySearches(body []byte) []Search {
    var allSearches []Search

    var queryResult QueryResult
    err := json.Unmarshal(body, &queryResult)
    if err != nil {
        fmt.Println(err)
    }

    issues := queryResult.Issues
    for i := range issues {
        search := parseQuerySearch(issues[i])
        allSearches = append(allSearches, search)
    }
    return allSearches
}

func parseQuerySearch(issue Issue) Search {
    var search Search

    search.Key = issue.Key
    search.Link = issue.Link
    search.Priority = issue.Fields.Priority["name"].(string)
    search.Status =  issue.Fields.Status["name"].(string)
    search.Reporter = issue.Fields.Reporter.DisplayName
    search.Assignee = parseQueryAssignee(issue)
    search.Title = issue.Fields.Summary

    return search
}

func parseQueryAssignee(issue Issue) string {
    if len(issue.Fields.Assignee.DisplayName) > 0 {
        return issue.Fields.Assignee.DisplayName
    }
    return "Not Assigned"
}

//for each issue, i need to create a search struct and add to the searches struct
