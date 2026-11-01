package com.homesweethome.service;

import com.homesweethome.entity.Pet;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.io.IOException;
import java.nio.file.*;
import java.util.Arrays;
import java.util.UUID;

@Service
public class PetPhotoStorage {
    private final Path root;
    public PetPhotoStorage(@Value("${homesweethome.uploads.pets:uploads/pets}") String path) {
        root = Path.of(path).toAbsolutePath().normalize();
    }
    private Path path(Pet pet, String extension) {
        Path result = root.resolve(pet.getFamilyId().toString())
                .resolve(pet.getId() + extension).normalize();
        if (!result.startsWith(root)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid photo path");
        return result;
    }
    public String save(Pet pet, MultipartFile file) {
        if (file == null || file.isEmpty() || file.getSize() > 5L * 1024 * 1024) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Photo must be between 1 byte and 5 MB");
        }
        try {
            byte[] bytes = file.getBytes();
            String extension;
            if (bytes.length >= 8 && Arrays.equals(Arrays.copyOf(bytes, 8),
                    new byte[]{(byte) 137, 80, 78, 71, 13, 10, 26, 10})) extension = ".png";
            else if (bytes.length >= 3 && bytes[0] == (byte) 255 && bytes[1] == (byte) 216 && bytes[2] == (byte) 255) extension = ".jpg";
            else throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a PNG or JPEG photo");
            Path target = path(pet, extension);
            Files.createDirectories(target.getParent());
            Files.write(target, bytes, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            Files.deleteIfExists(path(pet, extension.equals(".png") ? ".jpg" : ".png"));
            return "/api/pets/" + pet.getId() + "/photo";
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Photo storage is unavailable");
        }
    }
    public byte[] read(Pet pet) {
        try {
            Path png = path(pet, ".png"), jpg = path(pet, ".jpg");
            Path target = Files.isRegularFile(png) ? png : jpg;
            if (!Files.isRegularFile(target)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Photo unavailable");
            if (Files.size(target) > 5L * 1024 * 1024) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Photo exceeds size limit");
            return Files.readAllBytes(target);
        } catch (IOException ex) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Photo storage is unavailable");
        }
    }
    public String type(Pet pet) {
        return Files.isRegularFile(path(pet, ".png")) ? "image/png" : "image/jpeg";
    }
    public void delete(Pet pet) {
        try { Files.deleteIfExists(path(pet, ".png")); Files.deleteIfExists(path(pet, ".jpg")); }
        catch (IOException ex) { org.slf4j.LoggerFactory.getLogger(getClass()).warn("A pet photo could not be removed"); }
    }
    public void deleteAfterCommit(Pet pet) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { delete(pet); }
        });
    }
}
