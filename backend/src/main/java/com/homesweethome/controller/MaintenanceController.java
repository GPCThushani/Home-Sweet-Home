package com.homesweethome.controller;

import com.homesweethome.entity.MaintenanceItem;
import com.homesweethome.entity.MaintenanceRecord;
import com.homesweethome.entity.ServiceProvider;
import com.homesweethome.service.MaintenanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/maintenance")
@RequiredArgsConstructor
public class MaintenanceController {
    private final MaintenanceService maintenanceService;

    @GetMapping("/items/{familyId}")
    public List<MaintenanceItem> getItems(@PathVariable String familyId) {
        return maintenanceService.getItems(familyId);
    }

    @PostMapping("/items/{familyId}")
    public MaintenanceItem addItem(@PathVariable String familyId, @RequestBody MaintenanceItem item) {
        return maintenanceService.addItem(familyId, item);
    }

    @PutMapping("/items/{familyId}/{id}")
    public MaintenanceItem updateItem(@PathVariable String familyId, @PathVariable Long id, @RequestBody MaintenanceItem item) {
        return maintenanceService.updateItem(familyId, id, item);
    }

    @PostMapping("/items/{familyId}/{id}/complete")
    public MaintenanceItem completeService(@PathVariable String familyId, @PathVariable Long id, Authentication auth) {
        String user = (auth != null && auth.getName() != null) ? auth.getName() : "Family Member";
        return maintenanceService.markServiceComplete(familyId, id, user);
    }

    @GetMapping("/items/{familyId}/{itemId}/history")
    public List<MaintenanceRecord> getHistory(@PathVariable String familyId, @PathVariable Long itemId) {
        return maintenanceService.getHistory(itemId);
    }

    @DeleteMapping("/items/{familyId}/{id}")
    public ResponseEntity<Void> deleteItem(@PathVariable String familyId, @PathVariable Long id) {
        maintenanceService.deleteItem(familyId, id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/providers/{familyId}")
    public List<ServiceProvider> getProviders(@PathVariable String familyId) {
        return maintenanceService.getProviders(familyId);
    }

    @PostMapping("/providers/{familyId}")
    public ServiceProvider saveProvider(@PathVariable String familyId, @RequestBody ServiceProvider provider) {
        maintenanceService.saveProvider(familyId, provider);
        return provider;
    }
}