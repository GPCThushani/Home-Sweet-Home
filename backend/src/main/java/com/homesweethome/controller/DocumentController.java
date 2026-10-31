package com.homesweethome.controller;

import com.homesweethome.dto.FamilyDocumentResponse;
import com.homesweethome.entity.Document;
import com.homesweethome.entity.FamilyProfile;
import com.homesweethome.repository.DocumentRepository;
import com.homesweethome.repository.FamilyProfileRepository;
import com.homesweethome.service.FamilyAccessService;
import com.homesweethome.service.FamilyDocumentStorage;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {
    private static final List<String> CATEGORIES = List.of("Personal", "Education", "Financial", "Property", "Vehicle", "Insurance", "Other");
    private final DocumentRepository documents;
    private final FamilyProfileRepository profiles;
    private final FamilyAccessService access;
    private final FamilyDocumentStorage storage;

    @GetMapping("/{familyId}")
    public List<FamilyDocumentResponse> list(@PathVariable UUID familyId) {
        access.requireMembership(familyId);
        return documents.findByFamilyIdOrderByUploadedAtDesc(familyId).stream().map(this::response).toList();
    }

    @GetMapping("/item/{id}")
    public FamilyDocumentResponse metadata(@PathVariable UUID id) { return response(findAccessible(id)); }

    @PostMapping(value = "/{familyId}/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Transactional
    public ResponseEntity<FamilyDocumentResponse> upload(
            @PathVariable UUID familyId, @RequestParam MultipartFile file,
            @RequestParam String title, @RequestParam String category,
            @RequestParam(required = false) String description,
            @RequestParam(required = false) UUID familyProfileId) {
        access.requireMembership(familyId);
        String safeTitle = required(title, "A document title is required", 255);
        String safeCategory = required(category, "A valid document category is required", 32);
        if (!CATEGORIES.contains(safeCategory)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a valid document category");
        FamilyProfile profile = null;
        if (familyProfileId != null) {
            profile = profiles.findById(familyProfileId).filter(candidate -> candidate.getFamily().getId().equals(familyId))
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Household profile not found in this family"));
        }
        String contentType = storage.validate(file);
        Document document = new Document();
        document.setFamilyId(familyId); document.setFamilyProfileId(profile == null ? null : profile.getId());
        document.setTitle(safeTitle); document.setCategory(safeCategory); document.setDescription(optional(description, 1000));
        document.setFileName(safeFileName(file.getOriginalFilename())); document.setContentType(contentType);
        document.setFileSize(file.getSize()); document.setUploadedAt(Instant.now()); document.setUploadedBy(access.authenticatedEmail());
        document = documents.saveAndFlush(document);
        storage.save(document, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(response(document));
    }

    @GetMapping("/{id}/file")
    public ResponseEntity<byte[]> download(@PathVariable UUID id) {
        Document document = findAccessible(id);
        if (document.getFileName() == null || document.getContentType() == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "This legacy document has no uploaded file");
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(document.getFileName(), StandardCharsets.UTF_8).build().toString())
                .contentType(MediaType.parseMediaType(document.getContentType())).body(storage.read(document));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        Document document = findAccessible(id);
        documents.delete(document);
        if (document.getFileName() != null) storage.removeAfterCommit(document);
        return ResponseEntity.noContent().build();
    }

    private Document findAccessible(UUID id) {
        Document document = documents.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Document not found"));
        access.requireMembership(document.getFamilyId());
        return document;
    }

    private FamilyDocumentResponse response(Document document) {
        String profileName = document.getFamilyProfileId() == null ? null : profiles.findById(document.getFamilyProfileId())
                .filter(profile -> profile.getFamily().getId().equals(document.getFamilyId())).map(FamilyProfile::getName).orElse(null);
        return new FamilyDocumentResponse(document.getId(), document.getFamilyId(), document.getFamilyProfileId(), profileName,
                document.getTitle(), document.getDescription(), document.getCategory(), document.getFileName(), document.getContentType(),
                document.getFileSize() == null ? 0 : document.getFileSize(), document.getUploadedAt(), document.getFamilyProfileId() == null,
                "/api/documents/" + document.getId() + "/file");
    }

    private String required(String value, String message, int max) {
        String result = optional(value, max);
        if (result == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        return result;
    }

    private String optional(String value, int max) {
        if (value == null || value.trim().isEmpty()) return null;
        String result = value.trim();
        if (result.length() > max) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document details are too long");
        return result;
    }

    private String safeFileName(String value) {
        String result = value == null ? "document" : value.replaceAll("[\\\\/\\p{Cntrl}]", "_").trim();
        if (result.isEmpty()) result = "document";
        return result.substring(0, Math.min(result.length(), 255));
    }
}
