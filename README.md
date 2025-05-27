Overview
========

This is the fork of [grpc-angular-spring-boot-demo](https://github.com/juliusz-cwiakalski/grpc-angular-spring-boot-demo/tree/master/chat-proxy), I have just updated the frontend libraries and made it work

Goal of this project is to demonstrate [gRPC](https://grpc.io/) based communication between Angular application and java backend.

Main benefits of this approach:

* server and client stubs are generated automatically out of formal API description in proto format
* proto messages are backward compatible so it's easy to add new fields without breaking code
* streaming support

Example definition of proto gRPC service:

    service ChatService {
      rpc ReceiveMessages (ReceiveMessagesRequests) returns (stream ChatMessage) {}
      rpc SendMessage (ChatMessage) returns (google.protobuf.Empty) {}
      rpc Ping (ChatMessage) returns (ChatMessage) {}
    }

    message ChatMessage {
        string message = 1;
        string user = 2;
        google.protobuf.Timestamp timestamp = 3;
    }

There's no direct way to call gRPC from browser so additional proxy is required to translate http calls into gRPC calls. [Envoy](https://www.envoyproxy.io/) solves this problem.

*Disclaimer* this is just a PoC/demo. It's rather quick and dirty. Focused mostly on getting it all running togheter. Further improvemetns/cleanup to come in future :)

Building and starting
=====================

*Disclaimer:* setup is tested on ubuntu. Might need some adjustments on Windows machines.

Build and start frontend and backend without docker and use proxy in docker
---------------------------------------------------
### Prerequisites:

* maven
* npm
* protoc
* docker

### Backend
    cd ${PROJECT_ROOT}
    mvn install
    cd ${PROJECT_ROOT}/chat-backend-grpc/
    mvn spring-boot:run

### Frontend
    cd ${PROJECT_ROOT}/ng-chatapp/
    // optionally required - npm_config_target_arch=x64 npm i grpc
    npm install
    npm run compile
    npm run start

### Start proxy
    ${PROJECT_ROOT}/chat-proxy/start-local.sh

### Enjoy chat :P

Open your favourite browser and navigate to http://localhost:8080/


Building and starting with docker compose
-----------------------------------------
    cd ${PROJECT_ROOT}/ng-chatapp/
    npm run compile
    cd ${PROJECT_ROOT}
    mvn install
    docker-compose build
    docker-compose up

Open in browser http://locahost:28080/

### Further improvements in docker buld
Current setup requires java app build and proto->typescript compilation outside of docker. Next step is to do it inside docker so then maven/npm/protoc would not be prerequiste to build.

Most important files
====================

* [chat-proto/src/main/proto/chat.proto](chat-proto/src/main/proto/chat.proto) - gRPC / proto messages definitions
* [chat-backend-grpc/src/main/java/pl/jcw/demo/chat/backend/grpc/ChatServiceImpl.java](chat-backend-grpc/src/main/java/pl/jcw/demo/chat/backend/grpc/ChatServiceImpl.java) - java service implementation
* [ng-chatapp/src/app/api.service.ts](ng-chatapp/src/app/api.service.ts) - typescript service client implementation
* [chat-proxy/envoy(-local).yaml](chat-proxy/envoy.yaml) - envoy proxy configuration

Adding new services and testing locally
=======================================

To add new service:
1. Add definition in chat.proto
2. Maven build of chat-proto project (this will generate java stub)
3. Implement new service in chat-backend-grpc
4. Compile typescript client code: npm run compile
5. Implement clinent consumer in app

One disadvantage of gRPC is that it's binary format - not that easy to play with it as with JSON. Fortounately there's great GUI client (like POSTMAN) for gRPC -> [BloomRPC](https://github.com/uw-labs/bloomrpc). I find it even more convinient that POSTMAN/JSON. It has access to formal API definition so it's able to generate nice requests with all the parameters out of the box.

Project setup notes / troubleshooting
=====================================

### Create webapp

    ng new chat-webapp

    npm install --save-dev @angular/cli @angular-devkit/build-angular @angular/compiler @angular/compiler-cli grpc_tools_node_protoc_ts @types/node grpc-tools

    npm install --save grpc tls stream os fs ts-protoc-gen protoc path grpc-web-client google-protobuf @types/google-protobuf @improbable-eng/grpc-web


### Fix compilation error: TS2304: Cannot find name 'Buffer'
Add node types to chat-webapp/src/tsconfig.app.json

    "compilerOptions": {
        "types": ["node"]
    },

References
==========

* https://github.com/kmturley/angular-nest-grpc - helped me to get initial setup of envoy proxy and understand how to call gRPC from typescript


Demo
==========

* [demo 1](./demo/Screen%20Recording%202025-05-19%20at%2010.55.52%E2%80%AFPM.mov)
  * Envoy proxy translates gRPC for browser to understand. It converts the internal HTTP/2 calls to simple POST HTTP/1.1 calls. Need to check the behaviour for HTTP/2 though (todo). Backend and envoy communicates though regular gRPC. 

Insight
==========

* chat.proto contains prototype with models and function to be stubbed in UI 
* UI generates stub when compiled, we can use Client.function to call method directly
* Backend generates classes for server when compiled and provide the actual logic inside `ChatServiceImpl`
