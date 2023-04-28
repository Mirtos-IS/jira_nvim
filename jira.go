package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

var token = apiToken()
var paragraph = "paragraph"

type Token struct {
    User string
    Token string
}

type Ticket struct {
    Id string
    TicketNumber string `json:"key"`
    Fields Fields
}

type Fields struct {
    Summary string
    Reporter Creator
    Created string
    Updated string
    Priority map[string]any //This is a nice way with i don't want to struct the data
    Status map[string]any
    Description Description
    Comment map[string]any
}

type Creator struct {
    DisplayName string
}

type Description struct {
    Content []Content
}

type Content struct {
    Type string
    Content []InnerContent
}

type InnerContent struct {
    Type string
    Text string
}


func redirectPolicyFunc(request *http.Request, via []*http.Request) error{
    request.SetBasicAuth(token.User, token.Token)
  return nil
}

func apiToken() Token {
    byteValue, err := ioutil.ReadFile("./.pass")
    if err != nil {
        fmt.Println("couldn't find file .pass with credentials")
    }

    var token Token
    err = json.Unmarshal(byteValue, &token)
    if err != nil {
        fmt.Println(err)
    }

    return token
}

func parseJiraTicket(body []byte) string {
    var ticket Ticket
    err := json.Unmarshal(body, &ticket)
    if err != nil {
        fmt.Println(err)
    }
    parseDescription(&ticket)
    return "test"
}

func parseDescription(ticket *Ticket) {
    content := ticket.Fields.Description.Content
    for i := range content {
        if content[i].Type != paragraph {
            continue
        }
        fmt.Println(content[i].Content[0].Text)
    }
}

func main() {
    client := &http.Client{
        CheckRedirect: redirectPolicyFunc,
    }

    request, err := http.NewRequest("GET", "https://turnoverbnb.atlassian.net/rest/api/3/issue/TBB-5539", nil)
    request.SetBasicAuth(token.User, token.Token)

    resp, err := client.Do(request)
    if err != nil {
        log.Fatalln(err)
    }
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        log.Fatalln(err)
    }
    parseJiraTicket(body)
}
