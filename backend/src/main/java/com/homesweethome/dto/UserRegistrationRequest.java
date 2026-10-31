package com.homesweethome.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

// A Java 'record' automatically handles getters, setters, and constructors for us!
public record UserRegistrationRequest(
    @NotBlank @Email String email,
    @NotBlank String password
) {
    @Override
    public String toString() {
        return "UserRegistrationRequest[redacted]";
    }
}
