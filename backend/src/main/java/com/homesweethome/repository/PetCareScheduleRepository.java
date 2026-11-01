package com.homesweethome.repository;
import com.homesweethome.entity.PetCareSchedule;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface PetCareScheduleRepository extends JpaRepository<PetCareSchedule, UUID> {
    List<PetCareSchedule> findByPetIdAndDeletedFalseOrderByStartDateDesc(UUID petId);
    List<PetCareSchedule> findByAutoTasksTrueAndActiveTrueAndDeletedFalse();
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from PetCareSchedule s where s.id = :id")
    Optional<PetCareSchedule> findForUpdate(@Param("id") UUID id);
    long countByPetIdAndDeletedFalse(UUID petId);
    List<PetCareSchedule> findByPetId(UUID petId);
}
