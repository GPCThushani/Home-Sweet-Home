package com.homesweethome.controller;
import com.homesweethome.entity.*;
import com.homesweethome.repository.PetDocumentRepository;
import com.homesweethome.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;

@RestController @RequestMapping("/api/pets/{petId}/documents") @RequiredArgsConstructor
public class PetDocumentController {
    private static final Set<String> CATEGORIES = Set.of("Vaccination Certificates", "Prescriptions", "Medical Reports",
            "Laboratory Results", "Registration Documents", "Insurance Documents", "Other");
    private final PetAccessService access;
    private final PetDocumentRepository documents;
    private final PetDocumentStorage storage;
    @GetMapping
    public List<PetDocument> list(@PathVariable UUID petId) {
        access.require(petId);
        return documents.findByPetIdOrderByUploadedAtDesc(petId);
    }
    @GetMapping("/{id}")
    public PetDocument metadata(@PathVariable UUID petId, @PathVariable UUID id) { return owned(petId, id); }
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE) @Transactional
    public ResponseEntity<PetDocument> upload(@PathVariable UUID petId, @RequestParam MultipartFile file,
            @RequestParam String title, @RequestParam String category) {
        Pet pet = access.require(petId);
        if (title == null || title.isBlank() || title.length() > 255 || !CATEGORIES.contains(category))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Title and valid category are required");
        String contentType = storage.validate(file);
        PetDocument document = new PetDocument();
        document.setPetId(petId); document.setFamilyId(pet.getFamilyId()); document.setTitle(title.trim());
        document.setCategory(category); document.setContentType(contentType);
        String name = file.getOriginalFilename() == null ? "document" : file.getOriginalFilename().replaceAll("[\\\\/\\p{Cntrl}]", "_");
        document.setFileName(name.substring(0, Math.min(name.length(), 255)));
        document.setFileSize(file.getSize()); document.setUploadedAt(Instant.now());
        document = documents.saveAndFlush(document);
        storage.save(document, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(document);
    }
    @GetMapping("/{id}/file")
    public ResponseEntity<byte[]> file(@PathVariable UUID petId, @PathVariable UUID id) {
        PetDocument document = owned(petId, id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(document.getFileName(), StandardCharsets.UTF_8).build().toString())
                .contentType(MediaType.parseMediaType(document.getContentType())).body(storage.read(document));
    }
    @DeleteMapping("/{id}") @Transactional
    public ResponseEntity<Void> delete(@PathVariable UUID petId, @PathVariable UUID id) {
        PetDocument document = owned(petId, id);
        documents.delete(document); storage.removeAfterCommit(document);
        return ResponseEntity.noContent().build();
    }
    private PetDocument owned(UUID petId, UUID id) {
        access.require(petId);
        return documents.findByIdAndPetId(id, petId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pet document not found"));
    }
}
