package com.homesweethome.dto;

import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.GlobalTask;
import java.time.ZonedDateTime;
import java.util.UUID;

// Preserve the frontend's nested membership-ID contract without serializing
// Hibernate entities, user credentials, or unrelated family/account fields.
public record TaskResponse(UUID id, FamilyRef family, String title, String description,
        String originModule, String status, MemberRef assignedTo, MemberRef createdBy,
        MemberRef completedBy, ZonedDateTime dueDate, ZonedDateTime createdAt, ZonedDateTime completedAt,
        UUID sourcePetId, UUID sourceCareScheduleId, UUID sourcePetEntryId) {
    public record FamilyRef(UUID id) {}
    public record UserRef(UUID id, String email) {}
    public record MemberRef(UUID id, String nickname, UserRef user) {
        static MemberRef from(FamilyMember member) {
            return member == null ? null : new MemberRef(member.getId(), member.getNickname(),
                new UserRef(member.getUser().getId(), member.getUser().getEmail()));
        }
    }
    public static TaskResponse from(GlobalTask task) {
        return new TaskResponse(task.getId(), new FamilyRef(task.getFamily().getId()), task.getTitle(),
            task.getDescription(), task.getOriginModule(), task.getStatus(), MemberRef.from(task.getAssignedTo()),
            MemberRef.from(task.getCreatedBy()), MemberRef.from(task.getCompletedBy()), task.getDueDate(),
            task.getCreatedAt(), task.getCompletedAt(), task.getSourcePetId(),
            task.getSourceCareScheduleId(), task.getSourcePetEntryId());
    }
}
