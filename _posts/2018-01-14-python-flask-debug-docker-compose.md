---
layout: post
title: Debugging a Python Flask Application in a Container with Docker Compose
categories: [Blog]
tags: [python, flask, docker, containers]
---

Writing and debugging Python applications by themselves isn't hard: Just [kick it off with pdb and you're in the debugger](https://github.com/trstringer/cli-debugging-cheatsheets/blob/master/python.md#python-command-line-debugging-cheatsheet).

But when you start adding layers on top of it like Flask (web framework), Gunicorn (WSGI), Docker containers, and some form of container orchestration it is no longer a trivial task to break into the debugger.

## Container orchestration?

The "outermost" component mentioned above needs a little explanation. Yes, there will be times when your web APIs and applications are standalone and require no other external components. But typically there is a requirement for your web app to communicate with other services (persisting data in an RDBMS, making other service calls, using a caching layer, etc.).

My example application does just that: it's a Python Flask application that relies on and communicates with a Redis cache.

![Python and Flask with a Redis cache](/images/python-flask-redis.png)

Anybody that has worked with multiple containers for any amount of time knows this isn't a trivial thing to run, much less debug.

Worth noting, even though I very much prefer Kubernetes, I feel like Docker Compose is still the best tooling for container orchestration on localhost for my inner-loop development (develop, run, debug … all locally).

*2020-05-26 Update: I'm not sure this is the case for me anymore, I think there are a few ways to test locally with containerized applications. Maybe more to come in a future blog post.*

## Sample application

The sample project consists of a Flask application, a docker-compose configuration, and a Dockerfile. The entire repository containing this application can be found [here (GitHub)](https://github.com/trstringer/python-flask-docker-compose-debugging). For viewing pleasure and simplicity sake, though, I've placed app.py, Dockerfile, and docker-compose.yml below.

```python
from flask import Flask, jsonify, request
import redis

app = Flask(__name__)

@app.route('/')
def default_route():
    """Default route to return a simple message"""

    return jsonify('hello world')

@app.route('/message', methods=['GET'])
@app.route('/message/<new_message>', methods=['POST'])
def message_handler(new_message=None):
    """Handle the getting and setting of the message"""

    redis_client = redis.StrictRedis(host='redis')

    if request.method == 'GET':
        output = redis_client.get('message')
        # import pdb; pdb.set_trace()
        if output:
            return jsonify(dict(message=output.decode('utf-8')))

        return jsonify(dict(message='no output found for new_message'))

    redis_client.set('message', new_message)
    return jsonify(dict(message='set new_message'))

if __name__ == '__main__':
    app.run('0.0.0.0', 8000, debug=True)
```

Above is the app.py module which encapsulates our entire, but simple, Flask API. It has two effective routes: the default route which just prints out "hello world" (a good quick test things are generally working), and a route that handles GET and POST to either retrieve the message or set the message, which is stored in a Redis cache. The message_handler() is the component of the Flask application that talks to Redis.

Taking this a step further, a simple way to containerize this Flask application is with the following Dockerfile:

```dockerfile
FROM python:alpine3.6
WORKDIR /usr/src/app
EXPOSE 8000

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["gunicorn", "--workers=2", "--bind=0.0.0.0:8000", "app:app"]
```

The important part to note here is that the image's CMD is set to call Gunicorn (a production-quality WSGI) on my Flask application.

Finally, let's tie this all into using a Redis cache by specifying these multiple containers in a configuration for Docker Compose to handle:

```yaml
version: '3'
services:
  svc1:
    build: .
    links:
      - redis
    ports:
      - "8000:8000"
  redis:
    image: redis:latest
```

Our Docker Compose configuration just defines two services: the Flask application and the Redis cache. It's important to note that we must "link" the redis service to svc1(more on linking below).

## Running (not debugging) the application

Before we talk about breaking into the debugger, let's see this application running first. In the root of the repository/project, run the following:

```
$ docker-compose up --build -d
```

And then when the application is up and running you should be able add a new "message" to the application by running `curl -X POST localhost:8000/message/newmessage` and then retrieve the message with `curl localhost:8000/message`.

Here's a quick demo of this running locally in Docker Compose:

![Docker Compose demo](/images/docker-compose.gif)

## Debugging the application

Programming without a debugger is like building a house without a tape measure. You're going to need to use it… a lot. But with all of these moving parts (Gunicorn, containers, Docker Compose) it's not a straightforward operation to break into the debugger.

Here's how you can break on entry into pdb for a Flask application:

```
$ docker-compose run -p 8000:8000 svc1 python3 -m pdb app.py
```

*Note: make sure you run docker-compose buildif you made code changes (like adding a breakpoint, etc.)*

There are a few things going on here. First I'm using docker-compose run to run a single service, svc1. Note above in my docker-compose configuration I "link"ed the redis service to svc1. Because of that link, that container will also be brought up.

The other important component is undoubtedly a common operation for a Python developer... `python3 -m pdb app.py`. This is how we use pdb to interactively debug (in this case, I want to debug my Flask application). We are not going through Gunicorn by specifying this explicit command (we don't want to debug through our WSGI, we just want to directly invoke the Flask application).

The experience now is that we break on entry. Back up to app.py, you'll see I've commented out `import pdb; pdb.set_trace()` on line 21. Uncommenting that out before running Docker Compose will give you a breakpoint. Continuing after the initial break on entry would hit that breakpoint for interactive debugging when making a GET request to the message route. Here's how the experience looks:

![Docker Compose demo with debugging](/images/docker-compose2.gif)

## Summary

When writing production-level software with microservices and Python Flask, it is essential to be able to break into the debugger. We've taken a fairly common, but robust, architecture with Python, Flask, Gunicorn, Docker, and Docker Compose and broke into the interactive debugger, pdb. I hope you have enjoyed this illustration!
