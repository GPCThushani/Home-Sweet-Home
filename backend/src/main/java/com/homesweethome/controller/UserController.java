package com.homesweethome.controller;

import com.homesweethome.dto.AuthenticationResponse;
import com.homesweethome.dto.UserRegistrationRequest;
import com.homesweethome.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController // Tells Spring this handles API web requests
@RequestMapping("/api/users") // The base URL for this controller
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> registerUser(@RequestBody UserRegistrationRequest request) {
        return ResponseEntity.ok(userService.registerUser(request.email(), request.password()));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthenticationResponse> loginUser(@RequestBody UserRegistrationRequest request) {
        return ResponseEntity.ok(userService.loginUser(request.email(), request.password()));
    }
}