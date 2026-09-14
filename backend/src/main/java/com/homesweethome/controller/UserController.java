package com.homesweethome.controller;

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
    public ResponseEntity<String> registerUser(@RequestBody UserRegistrationRequest request) {
        // Pass the data from the incoming request to our Service layer
        String newUser = userService.registerUser(request.email(), request.password());
        
        // Return a 200 OK status along with the newly created user data
        return ResponseEntity.ok(newUser);
    }
}