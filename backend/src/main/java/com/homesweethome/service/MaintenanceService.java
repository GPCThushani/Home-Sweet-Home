package com.homesweethome.service;

import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MaintenanceService {
    private final MaintenanceItemRepository itemRepository;
    private final MaintenanceRecordRepository recordRepository;
    private final ServiceProviderRepository providerRepository;

    public List<MaintenanceItem> getItems(String familyId) {
        return itemRepository.findByFamilyIdAndActiveTrueOrderByIdAsc(familyId);
    }

    public List<ServiceProvider> getProviders(String familyId) {
        return providerRepository.findByFamilyId(familyId);
    }

    @Transactional
    public ServiceProvider saveProvider(String familyId, ServiceProvider provider) {
        provider.setFamilyId(familyId);
        return providerRepository.save(provider);
    }

    @Transactional
    public MaintenanceItem addItem(String familyId, MaintenanceItem item) {
        item.setFamilyId(familyId);
        if (item.getLastServicedDate() == null) {
            item.setLastServicedDate(LocalDate.now());
        }
        if (item.getNextDueDate() == null && item.getIntervalDays() != null) {
            item.setNextDueDate(item.getLastServicedDate().plusDays(item.getIntervalDays()));
        }
        return itemRepository.save(item);
    }

    @Transactional
    public MaintenanceItem updateItem(String familyId, Long id, MaintenanceItem incoming) {
        MaintenanceItem item = itemRepository.findByIdAndFamilyId(id, familyId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Maintenance item not found"));
        
        item.setTitle(incoming.getTitle());
        item.setCategory(incoming.getCategory());
        item.setIntervalDays(incoming.getIntervalDays());
        
        // Count the new next service date starting from the last serviced date (or today if null)
        LocalDate baseDate = item.getLastServicedDate() != null ? item.getLastServicedDate() : LocalDate.now();
        if (item.getIntervalDays() != null) {
            item.setNextDueDate(baseDate.plusDays(item.getIntervalDays()));
        }
        return itemRepository.save(item);
    }

    @Transactional
    public MaintenanceItem markServiceComplete(String familyId, Long itemId, String username) {
        MaintenanceItem item = itemRepository.findByIdAndFamilyId(itemId, familyId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Maintenance item not found"));

        LocalDate today = LocalDate.now();
        item.setLastServicedDate(today);

        if (item.getIntervalDays() != null) {
            item.setNextDueDate(today.plusDays(item.getIntervalDays()));
        }

        MaintenanceRecord record = new MaintenanceRecord();
        record.setFamilyId(familyId);
        record.setItemId(itemId);
        record.setServiceDate(today);
        record.setCompletedBy(username);
        record.setNotes("Service completed successfully.");
        recordRepository.save(record);

        return itemRepository.save(item);
    }

    public List<MaintenanceRecord> getHistory(Long itemId) {
        return recordRepository.findByItemIdOrderByServiceDateDesc(itemId);
    }

    @Transactional
    public void deleteItem(String familyId, Long itemId) {
        MaintenanceItem item = itemRepository.findByIdAndFamilyId(itemId, familyId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        recordRepository.deleteByItemId(itemId);
        itemRepository.delete(item);
    }
}