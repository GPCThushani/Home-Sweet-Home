package com.homesweethome.dto;

// A Java 'record' automatically handles getters, setters, and constructors for us!
public record UserRegistrationRequest(
    String email,
    String password
) {}