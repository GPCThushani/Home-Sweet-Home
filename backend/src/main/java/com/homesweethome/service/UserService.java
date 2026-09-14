package com.homesweethome.service;

import com.homesweethome.entity.User;
import com.homesweethome.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    // Registers a new user
    public User registerUser(String email, String rawPassword) {
        // Check if user already exists
        Optional<User> existingUser = userRepository.findByEmail(email);
        if (existingUser.isPresent()) {
            throw new IllegalArgumentException("A user with this email already exists.");
        }

        // TODO: Hash the password securely using Spring Security BCrypt later
        String hashedPassword = rawPassword; 

        User newUser = User.builder()
                .email(email)
                .passwordHash(hashedPassword)
                .build();

        return userRepository.save(newUser);
    }

    // Finds a user by email (useful for login)
    public Optional<User> getUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }
}