package com.homesweethome.service;
import com.homesweethome.entity.PetDocument;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import java.nio.file.*;
import java.io.IOException;

@Service
public class PetDocumentStorage {
    private final Path root;
    public PetDocumentStorage(@Value("${homesweethome.uploads.pet-documents:uploads/pet-documents}") String directory) {
        root = Path.of(directory).toAbsolutePath().normalize();
    }
    private Path path(PetDocument doc) {
        Path target = root.resolve(doc.getFamilyId().toString()).resolve(doc.getPetId().toString())
                .resolve(doc.getId() + ".blob").normalize();
        if (!target.startsWith(root)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid document path");
        return target;
    }
    public String validate(MultipartFile file) {
        if (file == null || file.isEmpty() || file.getSize() > 10L * 1024 * 1024)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document must be between 1 byte and 10 MB");
        String name = file.getOriginalFilename() == null ? "" : file.getOriginalFilename().toLowerCase();
        try {
            byte[] header = file.getInputStream().readNBytes(8);
            if (name.endsWith(".pdf") && header.length >= 5 && header[0]=='%' && header[1]=='P' && header[2]=='D' && header[3]=='F' && header[4]=='-') return "application/pdf";
            if (name.endsWith(".png") && header.length == 8 && header[0]==(byte)137 && header[1]==80 && header[2]==78 && header[3]==71 && header[4]==13 && header[5]==10 && header[6]==26 && header[7]==10) return "image/png";
            if ((name.endsWith(".jpg") || name.endsWith(".jpeg")) && header.length >= 3 && header[0]==(byte)255 && header[1]==(byte)216 && header[2]==(byte)255) return "image/jpeg";
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a PDF, JPG, JPEG or PNG document");
        } catch (IOException ex) { throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage unavailable"); }
    }
    public void save(PetDocument doc, MultipartFile file) {
        validate(file);
        try {
            Path target = path(doc);
            Files.createDirectories(target.getParent());
            Files.write(target, file.getBytes(), StandardOpenOption.CREATE_NEW);
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCompletion(int status) {
                    if (status != STATUS_COMMITTED) remove(target);
                }
            });
        } catch (IOException ex) { throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage unavailable"); }
    }
    public byte[] read(PetDocument doc) {
        try {
            Path target = path(doc);
            if (!Files.isRegularFile(target)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Document file unavailable");
            if (Files.size(target) > 10L * 1024 * 1024) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Document exceeds size limit");
            return Files.readAllBytes(target);
        } catch (IOException ex) { throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Document storage unavailable"); }
    }
    public void removeAfterCommit(PetDocument doc) {
        Path target = path(doc);
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { remove(target); }
        });
    }
    private void remove(Path target) {
        try { Files.deleteIfExists(target); }
        catch (IOException ex) { org.slf4j.LoggerFactory.getLogger(getClass()).warn("A pet document file could not be removed"); }
    }
}
