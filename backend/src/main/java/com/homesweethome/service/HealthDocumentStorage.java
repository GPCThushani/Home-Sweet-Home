package com.homesweethome.service;

import com.homesweethome.entity.HealthDocument;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import java.nio.file.*;
import java.io.IOException;

@Service
public class HealthDocumentStorage {
    private final Path root;
    public HealthDocumentStorage(@Value("${homesweethome.uploads.health:uploads/health}") String directory) {
        root = Path.of(directory).toAbsolutePath().normalize();
    }
    private Path path(HealthDocument document) {
        Path result = root.resolve(document.getFamilyId()).resolve(document.getFamilyMemberId())
                .resolve(document.getId() + ".blob").normalize();
        if (!result.startsWith(root)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid document scope");
        return result;
    }
    public String contentType(byte[] bytes) {
        if (bytes.length >= 5 && new String(bytes, 0, 5, java.nio.charset.StandardCharsets.US_ASCII).equals("%PDF-")) return "application/pdf";
        if (bytes.length >= 8 && bytes[0] == (byte)137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71 && bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10) return "image/png";
        if (bytes.length >= 3 && bytes[0] == (byte)255 && bytes[1] == (byte)216 && bytes[2] == (byte)255) return "image/jpeg";
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a PDF, PNG or JPEG document");
    }
    public void save(HealthDocument document, MultipartFile file) {
        if (file.isEmpty() || file.getSize() > 10 * 1024 * 1024) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document must be between 1 byte and 10 MB");
        try {
            byte[] bytes = file.getBytes();
            contentType(bytes);
            Path target = path(document);
            Files.createDirectories(target.getParent());
            Files.write(target, bytes, StandardOpenOption.CREATE_NEW);
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCompletion(int status) {
                    if (status != STATUS_COMMITTED) remove(target);
                }
            });
        } catch (IOException ex) { throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage is unavailable"); }
    }
    public byte[] read(HealthDocument document) {
        try {
            Path target = path(document);
            if (!Files.isRegularFile(target)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Document file is unavailable");
            if (Files.size(target) > 10 * 1024 * 1024) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document exceeds download limit");
            return Files.readAllBytes(target);
        } catch (IOException ex) { throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage is unavailable"); }
    }
    public void removeAfterCommit(HealthDocument document) {
        if (!("/api/health/documents/" + document.getId() + "/file").equals(document.getFileUrl())) return;
        Path target = path(document);
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { remove(target); }
        });
    }
    private void remove(Path target) {
        try { Files.deleteIfExists(target); }
        catch (IOException ex) { org.slf4j.LoggerFactory.getLogger(getClass()).warn("A health document file could not be removed"); }
    }
}
