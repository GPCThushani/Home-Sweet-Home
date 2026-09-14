package com.homesweethome.repository;

import com.homesweethome.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    // Spring automatically writes the SQL to find a user by their email
    Optional<User> findByEmail(String email);
}
