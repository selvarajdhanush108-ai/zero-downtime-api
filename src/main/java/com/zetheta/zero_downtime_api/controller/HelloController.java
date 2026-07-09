package com.zetheta.zero_downtime_api.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Welcome to Zero Downtime CI/CD Pipeline!, v3";
    }

    @GetMapping("/hello")
    public String hello() {
        return "Hello, DevOps!, v3";
    }
    @GetMapping("/health")
    public String health() {
        return "Application is healthy!, v3";   
    }
    @GetMapping("/version")
    public String version() {
        return "Application version: v3";   
    }
    @GetMapping("/info")
    public String info() {
        return "This is a sample application to demonstrate zero downtime deployment using Kubernetes and Spring Boot!, v3";   
    }
    @GetMapping("/status")
    public String status() {
        return "Application is running smoothly!, v3";  
    }
    @GetMapping("/selector")
    public String selector() {
        return "Blue";   
    }   
}