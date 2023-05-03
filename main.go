package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

var token = apiToken()

func redirectPolicyFunc(request *http.Request, via []*http.Request) error{
    request.SetBasicAuth(token.User, token.Token)
  return nil
}

func apiToken() Token {
    byteValue, err := ioutil.ReadFile(".token")
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

func helpCommands() string {
    file, _ := ioutil.ReadFile("help.txt")
    return string(file)
}

func main() {
    args := os.Args[1:]

    if args[0] == "--query" {
        result, err := requestQueryJira(args[1])
        if err != nil {
            fmt.Println(err)
        }
        resultJson, err := json.Marshal(result)
        fmt.Printf(string(resultJson))
        return
    }
    if args[0] == "--ticket" {
        result, err := requestSingleTicket(args[1])
        if err != nil {
            fmt.Println(err)
        }

        resultJson, err := json.Marshal(result)
        fmt.Println(string(resultJson))
        return
    }
    if args[0] == "--help" {
        fmt.Println(helpCommands())
    }
    fmt.Println("invalid command")
    return
}
