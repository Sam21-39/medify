# 💊 Medication Refill Reminder Feature

## Overview

The Medication Refill Reminder feature helps users track their medicine stock and receive timely notifications when it's time to refill their medications. This prevents users from running out of critical medicines and ensures continuous adherence to their medication schedule.

---

## 🎯 Key Features

### 1. **Stock Tracking**

- Track total quantity of medicine (pills/doses)
- Automatically decrement quantity when medicine is marked as taken
- Display current quantity and days remaining on medicine cards

### 2. **Low Stock Alerts**

- Set custom refill reminder threshold (e.g., notify 7 days before running out)
- Visual indicators on medicine cards:
  - 🟢 **Green** - Adequate stock
  - 🟠 **Orange** - Low stock (below threshold)
  - 🔴 **Red** - Out of stock

### 3. **Smart Notifications**

- Automatic refill reminders when stock is low
- Out of stock alerts
- Refill confirmation notifications
- Calculated based on daily usage patterns

### 4. **Automatic Quantity Management**

- Quantity automatically decrements when medicine is taken
- Preserves quantity when medicine is skipped or missed
- Refill functionality to reset stock levels

---

## 📊 Technical Implementation

### Database Schema Changes

#### Medicine Entity Fields Added:

```dart
int? totalQuantity;        // Total pills/doses in the bottle
int? currentQuantity;      // Current remaining pills/doses
int? refillRemindDays;     // Notify when X days of medicine left
DateTime? lastRefillDate;  // Last time medicine was refilled
```

#### Computed Properties:

```dart
int? get daysRemaining;    // Days of medicine remaining based on daily usage
bool get isLowStock;       // Check if medicine stock is low
bool get isOutOfStock;     // Check if medicine is out of stock
```

### Key Components

#### 1. **RefillReminderService**

Located: `lib/core/services/refill_reminder_service.dart`

**Responsibilities:**

- Check medicine refill status
- Schedule refill reminder notifications
- Decrement medicine quantity when taken
- Refill medicine stock
- Get list of medicines needing refill
- Calculate estimated refill dates

**Key Methods:**

```dart
// Check all medicines and schedule refill reminders
Future<void> checkAndScheduleRefillReminders()

// Update medicine quantity after taking a dose
Future<void> decrementMedicineQuantity(int medicineId)

// Refill medicine stock
Future<void> refillMedicine(int medicineId, {int? newQuantity})

// Get list of medicines needing refill
Future<List<Medicine>> getMedicinesNeedingRefill()

// Get stock status description
String getStockStatusDescription(Medicine medicine)
```

#### 2. **AddEditMedicinePage Updates**

Located: `lib/presentation/pages/add_edit_medicine_page.dart`

**New UI Elements:**

- Refill Tracking toggle switch
- Total Quantity input field
- Refill Reminder Days input field (1-90 days)
- Visual info card explaining the feature

**Default Values:**

- Refill reminder: 7 days
- Total quantity: User-defined
- Current quantity: Same as total quantity on creation

#### 3. **MedicineCard Updates**

Located: `lib/presentation/widgets/medicine_card.dart`

**Stock Level Indicator:**

- Displays below the intake timing
- Color-coded status icon
- Shows quantity and days remaining
- Adapts to medicine active/inactive state

#### 4. **MedicineLogCubit Integration**

Located: `lib/presentation/blocs/medicine_log/medicine_log_cubit.dart`

**Automatic Quantity Decrement:**

- When medicine is marked as taken
- Checks if stock is low after decrement
- Triggers refill notifications if needed

---

## 🎨 User Experience

### Adding a Medicine with Refill Tracking

1. **Navigate** to Add Medicine page
2. **Fill** basic details (name, dosage, reminders)
3. **Toggle** "Refill Tracking" switch
4. **Enter** total quantity (e.g., 30 pills)
5. **Set** refill reminder days (e.g., 7 days)
6. **Save** the medicine

### Viewing Stock Status

**On Medicine Card:**

- Green checkmark: "30 doses (15 days left)"
- Orange warning: "Low stock (3 days left)"
- Red error: "Out of stock"

### Receiving Refill Notifications

**Low Stock:**

```
🔔 Refill Reminder
Only 7 days of Aspirin remaining. Consider refilling.
```

**Out of Stock:**

```
⚠️ Medicine Out of Stock
Aspirin is out of stock! Please refill immediately
to continue your medication schedule.
```

**After Refill:**

```
✅ Medicine Refilled
Aspirin has been refilled successfully. Current stock: 30 doses.
```

---

## 🔄 Automatic Workflows

### Daily Startup Check

```
App Launch → Check all active medicines →
Identify low stock/out of stock →
Schedule immediate notifications
```

### When Medicine is Taken

```
Mark as Taken → Decrement quantity →
Check if low stock →
Schedule refill notification if needed
```

### Stock Level Calculation

```
Daily Usage = Number of reminder times per day
Days Remaining = Current Quantity ÷ Daily Usage
Is Low Stock? = Days Remaining ≤ Refill Remind Days
```

---

## 💡 Usage Examples

### Example 1: Daily Vitamin

```
Medicine: Vitamin D
Total Quantity: 60 tablets
Reminder Times: 1 per day (morning)
Refill Reminder: 7 days

Calculation:
- Daily usage: 1 tablet
- Days supply: 60 days
- Low stock alert: When 7 days left (at 7 tablets)
```

### Example 2: Multiple Daily Doses

```
Medicine: Blood Pressure Medication
Total Quantity: 90 tablets
Reminder Times: 3 per day (morning, afternoon, evening)
Refill Reminder: 7 days

Calculation:
- Daily usage: 3 tablets
- Days supply: 30 days
- Low stock alert: When 7 days left (at 21 tablets)
```

### Example 3: As-Needed Medication

```
Medicine: Pain Reliever
Total Quantity: 24 tablets
Reminder Times: 2 per day (as needed)
Refill Reminder: 5 days

Calculation:
- Daily usage: 2 tablets (maximum)
- Days supply: 12 days
- Low stock alert: When 5 days left (at 10 tablets)
```

---

## 🧪 Testing Checklist

### Unit Tests

- [ ] Medicine entity computed properties
- [ ] RefillReminderService methods
- [ ] Stock level calculations
- [ ] Edge cases (0 quantity, null values)

### Integration Tests

- [ ] Quantity decrement on medicine taken
- [ ] Refill notification scheduling
- [ ] Stock status display on cards
- [ ] Refill workflow end-to-end

### UI Tests

- [ ] Refill tracking toggle
- [ ] Input validation (quantity, days)
- [ ] Stock indicator rendering
- [ ] Notification display

### Manual Testing Steps

1. **Create Medicine with Refill Tracking**

   - Add new medicine
   - Enable refill tracking
   - Enter 10 tablets, 3 days reminder
   - Set 2 daily reminders
   - Save and verify

2. **Test Quantity Decrement**

   - Mark medicine as taken
   - Verify quantity decrements
   - Check days remaining updates
   - Verify stock indicator changes

3. **Test Low Stock Alert**

   - Reduce quantity to threshold
   - Verify orange warning appears
   - Check notification received
   - Verify message content

4. **Test Out of Stock**

   - Reduce quantity to 0
   - Verify red error appears
   - Check out of stock notification
   - Verify can't take more doses

5. **Test Refill**
   - Open medicine edit page
   - Update total quantity
   - Verify current quantity resets
   - Verify lastRefillDate updates
   - Check refill notification

---

## 🐛 Known Issues & Limitations

### Current Limitations

1. **No Partial Dose Tracking**: Assumes whole doses/pills
2. **Simple Calculation**: Based on scheduled reminders, not actual usage
3. **Manual Refill Only**: No pharmacy integration
4. **Single Bottle Tracking**: Can't track multiple bottles

### Future Enhancements

1. **Prescription Scanning**: OCR to auto-fill details
2. **Pharmacy Integration**: Order refills directly
3. **Smart Predictions**: ML-based usage prediction
4. **Multi-Bottle Tracking**: Track main + backup supplies
5. **Refill History**: View past refill dates and patterns
6. **Sharing**: Share refill reminders with caregivers

---

## 📚 API Reference

### Medicine Entity Extensions

```dart
// Get days of medicine remaining
int? get daysRemaining

// Check if stock is low
bool get isLowStock

// Check if out of stock
bool get isOutOfStock
```

### RefillReminderService Methods

```dart
// Check and schedule refill reminders for all medicines
Future<void> checkAndScheduleRefillReminders()

// Decrement quantity after taking medicine
Future<void> decrementMedicineQuantity(int medicineId)

// Refill medicine to specified quantity
Future<void> refillMedicine(int medicineId, {int? newQuantity})

// Get all medicines that need refilling
Future<List<Medicine>> getMedicinesNeedingRefill()

// Calculate when refill will be needed
DateTime? calculateEstimatedRefillDate(Medicine medicine)

// Get human-readable stock status
String getStockStatusDescription(Medicine medicine)
```

---

## 🎓 Best Practices

### For Users

1. **Set Realistic Reminders**: Don't wait until last day
2. **Update After Refill**: Mark when you refill medicines
3. **Check Regularly**: Review stock levels weekly
4. **Plan Ahead**: Order refills during reminder window

### For Developers

1. **Validate Input**: Ensure positive integers only
2. **Handle Edge Cases**: Zero, null, negative values
3. **Clear Messages**: User-friendly notification text
4. **Test Thoroughly**: All stock level scenarios
5. **Log Events**: Track refills for analytics

---

## 📞 Support & Troubleshooting

### Common Issues

**Q: Stock indicator not showing**

- Ensure refill tracking is enabled
- Check totalQuantity is not null
- Verify reminder times are set

**Q: Quantity not decrementing**

- Check RefillReminderService is registered in DI
- Verify MedicineLogCubit has service injected
- Review logs for errors

**Q: Notifications not appearing**

- Check notification permissions
- Verify refillRemindDays is set
- Ensure medicine is active

**Q: Wrong days remaining calculation**

- Verify reminderTimes count
- Check currentQuantity value
- Review calculation logic

---

## 🔐 Data Privacy

- **All data stored locally** using ObjectBox
- **No cloud sync** for refill tracking
- **No pharmacy data** collected or shared
- **User controls all data** and can disable feature

---

## 📝 Version History

### v1.1.0 (Current)

- ✅ Initial refill reminder implementation
- ✅ Stock level tracking and display
- ✅ Automatic quantity decrement
- ✅ Low stock and out of stock notifications
- ✅ Refill functionality
- ✅ Visual stock indicators

### Future (v1.2.0)

- 🔮 Refill history tracking
- 🔮 Prescription photo storage
- 🔮 Pharmacy integration
- 🔮 Multi-bottle tracking
- 🔮 Caregiver sharing

---

## 🎉 Conclusion

The Medication Refill Reminder feature significantly enhances Medify by ensuring users never run out of their critical medications. With automatic tracking, smart notifications, and clear visual indicators, users can maintain better medication adherence and health outcomes.

**Next Steps:**

1. Complete thorough testing
2. Gather user feedback
3. Iterate based on real-world usage
4. Plan enhanced features for v1.2.0

---

**Documentation Generated:** October 21, 2025  
**Feature Status:** ✅ Implemented and Ready for Testing  
**Version:** 1.1.0
