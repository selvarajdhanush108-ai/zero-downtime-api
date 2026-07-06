package com.zetheta.zero_downtime_api.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Welcome to Zero Downtime CI/CD Pipeline!";
    }

    @GetMapping("/hello")
    public String hello() {
        return "Hello, DevOps!";
    }
}