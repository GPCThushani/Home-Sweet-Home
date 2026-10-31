package com.homesweethome.service;

import com.homesweethome.entity.Document;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Locale;

/** Opaque generated storage for general family documents, separate from health uploads. */
@Service
public class FamilyDocumentStorage {
    public static final long MAX_FILE_SIZE = 10L * 1024 * 1024;
    private final Path root;

    public FamilyDocumentStorage(@Value("${homesweethome.uploads.documents:uploads/documents}") String directory) {
        root = Path.of(directory).toAbsolutePath().normalize();
    }

    private Path path(Document document) {
        Path result = root.resolve(document.getFamilyId().toString())
                .resolve(document.getId() + ".blob").normalize();
        if (!result.startsWith(root)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid document scope");
        return result;
    }

    public String validate(MultipartFile file) {
        if (file == null || file.isEmpty() || file.getSize() > MAX_FILE_SIZE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document must be between 1 byte and 10 MB");
        }
        String name = file.getOriginalFilename() == null ? "" : file.getOriginalFilename();
        String extension = name.contains(".") ? name.substring(name.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT) : "";
        try {
            byte[] header = file.getInputStream().readNBytes(8);
            if (extension.equals("pdf") && startsWith(header, "%PDF-".getBytes())) return "application/pdf";
            if (extension.equals("png") && header.length == 8 && header[0] == (byte) 137 && header[1] == 80 && header[2] == 78 && header[3] == 71 && header[4] == 13 && header[5] == 10 && header[6] == 26 && header[7] == 10) return "image/png";
            if ((extension.equals("jpg") || extension.equals("jpeg")) && header.length >= 3 && header[0] == (byte) 255 && header[1] == (byte) 216 && header[2] == (byte) 255) return "image/jpeg";
            if (extension.equals("docx") && header.length >= 4 && header[0] == 'P' && header[1] == 'K' && header[2] == 3 && header[3] == 4) return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a PDF, JPG, JPEG, PNG or DOCX file");
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage is unavailable");
        }
    }

    private boolean startsWith(byte[] bytes, byte[] prefix) {
        if (bytes.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) if (bytes[i] != prefix[i]) return false;
        return true;
    }

    public void save(Document document, MultipartFile file) {
        validate(file);
        try {
            Path target = path(document);
            Files.createDirectories(target.getParent());
            Files.write(target, file.getBytes(), StandardOpenOption.CREATE_NEW);
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCompletion(int status) { if (status != STATUS_COMMITTED) remove(target); }
            });
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage is unavailable");
        }
    }

    public byte[] read(Document document) {
        try {
            Path target = path(document);
            if (!Files.isRegularFile(target)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Document file is unavailable");
            if (Files.size(target) > MAX_FILE_SIZE) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document exceeds download limit");
            return Files.readAllBytes(target);
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage is unavailable");
        }
    }

    public void removeAfterCommit(Document document) {
        Path target = path(document);
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { remove(target); }
        });
    }

    private void remove(Path target) {
        try { Files.deleteIfExists(target); }
        catch (IOException ex) { org.slf4j.LoggerFactory.getLogger(getClass()).warn("A family document file could not be removed"); }
    }
}
