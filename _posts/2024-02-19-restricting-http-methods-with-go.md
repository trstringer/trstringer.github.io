---
layout: post
title: Restrict HTTP Request Methods in Go 
categories: [Blog]
tags: [golang]
---

This is loosely part 2 of my latest blog post on [advancements in routing](https://trstringer.com/go-http-route-values/). One of the other new features in Go 1.22 is the ability to have the HTTP method enforced directly in the path. But let's first see what it is like to require an HTTP method _prior_ to this change:

```go
func sayHelloHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte(fmt.Sprintf("HTTP method %q not allowed", r.Method)))
		return
	}

	w.Write([]byte("Hello, world!"))
}

func main() {
	http.HandleFunc("/hi", sayHelloHandler)

	fmt.Println("Running server...")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		fmt.Printf("Error running server: %v\n", err)
		os.Exit(1)
	}
}
```

Here I create a simple HTTP server with a single route: `/hi`. I want to only handle `HTTP/GET` requests though, so in my handler I do the check to see if it is in fact a get. If not, respond accordingly. If it is, say hello.

With Go 1.22 we can put the `HTTP/GET` requirement in the path:

```go
func sayHelloHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Hello, world!"))
}

func main() {
	http.HandleFunc("GET /hi", sayHelloHandler)

	fmt.Println("Running server...")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		fmt.Printf("Error running server: %v\n", err)
		os.Exit(1)
	}
}
```

Now in my call to `http.HandleFunc` I specify a prefix of `GET` before the path and I no longer need to do this check directly in my handler. Now if I make a request with a different method, such as a `POST`, I get an HTTP/405 returned.

This is a really great way to define accepted methods and removing a lot of boilerplate code that we had to do prior to this!
