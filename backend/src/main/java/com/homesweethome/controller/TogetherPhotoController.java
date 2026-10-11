package com.homesweethome.controller;

import com.homesweethome.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.io.IOException;
import java.nio.file.*;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/together")
@RequiredArgsConstructor
public class TogetherPhotoController {

    private final FamilyMemberRepository familyMemberRepository;

    @Value("${homesweethome.uploads.together:uploads/together}")
    private String uploadRoot;

    private void requireFamilyMember(String familyId, Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sign in required");
        }
        UUID id;
        try {
            id = UUID.fromString(familyId);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid family ID");
        }
        if (!familyMemberRepository.existsByFamilyIdAndUserEmail(id, auth.getName())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Family membership required");
        }
    }

    @PostMapping(value = "/memories/{familyId}/photo", consumes = {MediaType.MULTIPART_FORM_DATA_VALUE, MediaType.APPLICATION_OCTET_STREAM_VALUE})
    public Map<String, String> upload(@PathVariable String familyId,
                                      @RequestParam(value = "file", required = false) MultipartFile file,
                                      Authentication auth) throws IOException {
        requireFamilyMember(familyId, auth);
        if (file == null || file.isEmpty() || file.getSize() > 10 * 1024 * 1024) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Photo must be between 1 byte and 10 MB");
        }
        String mime = file.getContentType();
        String extension = ".jpg";
        if (mime != null) {
            if (mime.equals("image/png")) extension = ".png";
            else if (mime.equals("image/webp")) extension = ".webp";
        }
        
        String name = UUID.randomUUID() + extension;
        Path dir = Paths.get(uploadRoot).toAbsolutePath().normalize().resolve(familyId).normalize();
        Files.createDirectories(dir);
        Path target = dir.resolve(name);
        
        try (var in = file.getInputStream()) {
            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
        }
        return Map.of("imageUrl", "/api/together/photos/" + familyId + "/" + name);
    }

    @GetMapping("/photos/{familyId}/{filename}")
    public ResponseEntity<Resource> photo(@PathVariable String familyId,
                                          @PathVariable String filename,
                                          Authentication auth) throws IOException {
        requireFamilyMember(familyId, auth);
        Path root = Paths.get(uploadRoot).toAbsolutePath().normalize();
        Path path = root.resolve(familyId).resolve(filename).normalize();
        if (!path.startsWith(root) || !Files.isRegularFile(path)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        String type = Files.probeContentType(path);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(type != null ? type : "image/jpeg"))
                .header(HttpHeaders.CACHE_CONTROL, "private, max-age=3600")
                .body(new UrlResource(path.toUri()));
    }
}