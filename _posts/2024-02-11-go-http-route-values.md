---
layout: post
title: Get HTTP Route Values in Go
categories: [Blog]
tags: [golang]
---

It seems like with every release, Go becomes better and better. [Go 1.22](https://tip.golang.org/doc/go1.22) is no different. There are a lot of great advancements in this new release, but one in particular is _really_ noteworthy: Improved **route handling**. The first advancement I want to highlight is getting route values. Before Go 1.22, this was either difficult to do with the standard library (lots of parsing!), or you had to use an external library. And if you've been in the Go world for any amount of time, you probably already know that us Go developers really like to just use the standard library.

Now with Go 1.22 we have the ability to pull route values easily!

Let's take this example: We want to expose a `/users` API that either lists out usernames, or it allows you specify a user with `/users/<name>` and you get some information about them.

I defined my routes like this:

```golang
	http.HandleFunc("/users/{name}", getUserHandler)
	http.HandleFunc("/users", getUserHandler)
```

And then I'm able to access the `name` value in my handler `getUserHandler`:

```golang
	username := r.PathValue("name")
```

If that's empty, I know the path `/users` was used, and just dump out all the users. I really like this new, and _much_ easier way, to get values from routes! Full working server code can be found below.

```golang
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type user struct {
	Name          string `json:"name"`
	FavoriteColor string `json:"favoriteColor"`
}

var allUsers = []user{
	{Name: "testuser1", FavoriteColor: "green"},
	{Name: "testuser2", FavoriteColor: "grey"},
}

func getUserHandler(w http.ResponseWriter, r *http.Request) {
	username := r.PathValue("name")
	if username == "" {
		allUsersJSON, _ := json.Marshal(allUsers)
		w.Write([]byte(allUsersJSON))
		return
	}
	for _, user := range allUsers {
		if user.Name == username {
			userJSON, _ := json.Marshal(user)
			w.Write([]byte(userJSON))
			return
		}
	}
	w.WriteHeader(http.StatusBadRequest)
	w.Write([]byte(fmt.Sprintf("unknown user: %s", username)))
}

func main() {
	http.HandleFunc("/users/{name}", getUserHandler)
	http.HandleFunc("/users", getUserHandler)

	fmt.Println("Running server...")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		fmt.Printf("Error running server: %v\n", err)
		os.Exit(1)
	}
}
```
