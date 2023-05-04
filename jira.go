package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

var paragraph = "paragraph"
var text = "text"

type Token struct {
    User string
    Token string
}

type Ticket struct {
    TicketNumber string
    Title string
    Reporter string
    Assignee string
    Priority string
    Status string
    Description string
    Comments []string
}

type JiraJson struct {
    Id string
    TicketNumber string `json:"key"`
    Fields TicketFields
}

type TicketFields struct {
    Summary string
    Reporter Creator
    Assignee Creator
    Created string
    Updated string
    Priority map[string]any //This is a nice way with i don't want to struct the data
    Status map[string]any
    Description Description
    Comment Comment
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
    Attrs map[string]any
}

type Comment struct {
    Comments []Comments
}

type Comments struct {
    Author map[string]any
    Body Body

}

type Body struct {
    Type string
    Content []Content
}

func parseJiraTicket(body []byte) *Ticket {
    var ticket Ticket
    var jirajson JiraJson
    err := json.Unmarshal(body, &jirajson)
    if err != nil {
        fmt.Println(err)
    }
    ticket.TicketNumber = jirajson.TicketNumber
    ticket.Description = parseDescription(&jirajson)
    ticket.Title = parseTitle(&jirajson)
    ticket.Priority = parsePriority(&jirajson)
    ticket.Reporter = parseReporter(&jirajson)
    ticket.Assignee = parseAssignee(&jirajson)
    ticket.Status = jirajson.Fields.Status["name"].(string)
    ticket.Comments = parseComments(&jirajson)

    return &ticket
}

func parseDescription(ticket *JiraJson) string {
    content := ticket.Fields.Description.Content
    return parseContent(content)
}

func parseAssignee(ticket *JiraJson) string {
    if ticket.Fields.Assignee.DisplayName != "" {
        return ticket.Fields.Assignee.DisplayName
    }
    return "Not Assigned"
}

func parseContent(content []Content) string {

    var parsedContent string
    for i := range content {
        if content[i].Type != paragraph {
            continue
        }
        parsedContent += parseInnerContent(content[i].Content) + "\n\n"
    }
    return parsedContent

}

func parseTitle(ticket *JiraJson) string {
    title := ticket.Fields.Summary
    return title
}

func parsePriority(ticket *JiraJson) string {
    priority := ticket.Fields.Priority["name"].(string)
    return priority
}

func parseReporter(ticket *JiraJson) string {
    priority := ticket.Fields.Reporter.DisplayName
    return priority
}

func parseComments(ticket *JiraJson) []string {
    comments := ticket.Fields.Comment.Comments
    var parsedComments []string
    for i := range comments {
        singleComment := comments[i].Author["displayName"].(string) + ": "
        singleComment += parseContent(comments[i].Body.Content)
        parsedComments = append(parsedComments, singleComment)

    }
    return parsedComments
}

func parseInnerContent(content []InnerContent) string {
    var parsedContent string
    for i := range content {
        if content[i].Type != text && content[i].Type != "mention" {
            continue
        }

        if content[i].Type == "mention" {
            parsedContent += content[i].Attrs["text"].(string)
        }
        parsedContent += content[i].Text

    }
    return parsedContent
}

func requestSingleTicket(ticketNumber string) (*Ticket, error) {
    client := &http.Client{
        CheckRedirect: redirectPolicyFunc,
    }

    baseURL := "https://turnoverbnb.atlassian.net/rest/api/3/issue/"
    request, err := http.NewRequest("GET", baseURL + ticketNumber, nil)
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
    ticket := parseJiraTicket(body)
    return ticket, nil
}



