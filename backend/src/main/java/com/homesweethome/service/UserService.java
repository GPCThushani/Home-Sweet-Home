package com.homesweethome.service;

import com.homesweethome.dto.AuthenticationResponse;
import com.homesweethome.entity.User;
import com.homesweethome.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    // Registers user, hashes password, and returns a JWT token + user data
    public AuthenticationResponse registerUser(String email, String rawPassword) {
        Optional<User> existingUser = userRepository.findByEmail(email);
        if (existingUser.isPresent()) {
            throw new IllegalArgumentException("A user with this email already exists.");
        }

        User newUser = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .build();

        User savedUser = userRepository.save(newUser);
        String token = jwtService.generateToken(savedUser);

        return new AuthenticationResponse(token, savedUser.getId(), savedUser.getEmail());
    }

    // Authenticates user and returns a JWT token + user data
    public AuthenticationResponse loginUser(String email, String rawPassword) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, rawPassword)
        );
        
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
                
        String token = jwtService.generateToken(user);

        return new AuthenticationResponse(token, user.getId(), user.getEmail());
    }
}