package com.homesweethome.controller;

import com.homesweethome.dto.AuthenticationResponse;
import com.homesweethome.dto.UserRegistrationRequest;
import com.homesweethome.entity.User;
import com.homesweethome.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.access.AccessDeniedException;
import java.util.Map;
import jakarta.validation.Valid;

@RestController // Tells Spring this handles API web requests
@RequestMapping("/api/users") // The base URL for this controller
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> registerUser(@Valid @RequestBody UserRegistrationRequest request) {
        return ResponseEntity.ok(userService.registerUser(request.email(), request.password()));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthenticationResponse> loginUser(@Valid @RequestBody UserRegistrationRequest request) {
        return ResponseEntity.ok(userService.loginUser(request.email(), request.password()));
    }

    // --- ADDED FALLBACK ENDPOINT ---
    @GetMapping("/by-email")
    public ResponseEntity<Map<String, Object>> getUserByEmail(@RequestParam String email, Authentication authentication) {
        if (authentication == null || !authentication.getName().equalsIgnoreCase(email)) {
            throw new AccessDeniedException("You cannot access another user");
        }
        User user = userService.getUserByEmail(email);
        return ResponseEntity.ok(Map.of("id", user.getId(), "email", user.getEmail()));
    }
}
