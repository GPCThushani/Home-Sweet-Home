package com.homesweethome.repository;

import com.homesweethome.entity.ServiceProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface ServiceProviderRepository extends JpaRepository<ServiceProvider, Long> {
    List<ServiceProvider> findByFamilyId(String familyId);
    Optional<ServiceProvider> findByIdAndFamilyId(Long id, String familyId);
}