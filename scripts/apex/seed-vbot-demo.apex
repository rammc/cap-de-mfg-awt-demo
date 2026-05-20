// =============================================================================
// VerdantBot Demo Seed Script (Phase 1)
// =============================================================================
// Idempotent: every block checks for an existing record and either logs
// [CREATE] for a new row or [SKIP-EXISTS] for an already-seeded one.
// Asset Telemetry uses the External_Id__c upsert pattern.
// Run via:  sf apex run --file scripts/apex/seed-vbot-demo.apex \
//                       --target-org christopher.ramm@cap-de-mfg-awt-demo.com
// =============================================================================

Savepoint sp = Database.setSavepoint();
try {

// ---------------------------------------------------------------------------
// Block 1: Account "VBOT Familie Schmidt"
// ---------------------------------------------------------------------------
System.debug('--- Block 1: Account ---');
Account acc;
List<Account> accs = [
    SELECT Id, Name FROM Account WHERE Name = 'VBOT Familie Schmidt' LIMIT 1
];
if (!accs.isEmpty()) {
    acc = accs[0];
    System.debug('[SKIP-EXISTS] Account ' + acc.Id);
} else {
    acc = new Account(
        Name = 'VBOT Familie Schmidt',
        BillingCity = 'Berlin',
        BillingCountry = 'DE',
        BillingPostalCode = '10115',
        BillingStreet = 'Demo-Allee 42',
        Phone = '+49 30 12345678',
        Type = 'Customer'
    );
    insert acc;
    System.debug('[CREATE] Account ' + acc.Id);
}

// ---------------------------------------------------------------------------
// Block 2: Contact "Anna Schmidt"
// ---------------------------------------------------------------------------
System.debug('--- Block 2: Contact ---');
Contact con;
List<Contact> cons = [
    SELECT Id, Email FROM Contact WHERE Email = 'anna.schmidt@example.vbot' LIMIT 1
];
if (!cons.isEmpty()) {
    con = cons[0];
    System.debug('[SKIP-EXISTS] Contact ' + con.Id);
} else {
    con = new Contact(
        AccountId = acc.Id,
        FirstName = 'Anna',
        LastName = 'Schmidt',
        Email = 'anna.schmidt@example.vbot',
        Phone = '+49 30 87654321',
        MailingCity = 'Berlin',
        MailingCountry = 'DE'
    );
    insert con;
    System.debug('[CREATE] Contact ' + con.Id);
}

// ---------------------------------------------------------------------------
// Block 3: Standard Pricebook (read-only lookup)
// ---------------------------------------------------------------------------
System.debug('--- Block 3: Pricebook ---');
Pricebook2 std = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
System.debug('[LOOKUP] Standard Pricebook ' + std.Id);

// ---------------------------------------------------------------------------
// Block 4: Product2 x 6
// ---------------------------------------------------------------------------
System.debug('--- Block 4: Products ---');
Map<String, Product2> productSpecs = new Map<String, Product2>();
productSpecs.put('VBOT_E150', new Product2(
    Name = 'VerdantBot E150', ProductCode = 'VBOT_E150', IsActive = true,
    Family = 'Mower',
    VBOT_Tier_Label__c = 'Entry',
    VBOT_Max_Area_Sqm__c = 500, VBOT_Battery_Capacity_Wh__c = 60,
    VBOT_Has_GPS__c = false, VBOT_Has_Lawn_AI__c = false
));
productSpecs.put('VBOT_C300', new Product2(
    Name = 'VerdantBot C300', ProductCode = 'VBOT_C300', IsActive = true,
    Family = 'Mower',
    VBOT_Tier_Label__c = 'Comfort',
    VBOT_Max_Area_Sqm__c = 1000, VBOT_Battery_Capacity_Wh__c = 90,
    VBOT_Has_GPS__c = false, VBOT_Has_Lawn_AI__c = false
));
productSpecs.put('VBOT_C500', new Product2(
    Name = 'VerdantBot C500', ProductCode = 'VBOT_C500', IsActive = true,
    Family = 'Mower',
    VBOT_Tier_Label__c = 'Comfort+',
    VBOT_Max_Area_Sqm__c = 1500, VBOT_Battery_Capacity_Wh__c = 110,
    VBOT_Has_GPS__c = false, VBOT_Has_Lawn_AI__c = false
));
productSpecs.put('VBOT_X800', new Product2(
    Name = 'VerdantBot X800', ProductCode = 'VBOT_X800', IsActive = true,
    Family = 'Mower',
    VBOT_Tier_Label__c = 'Pro',
    VBOT_Max_Area_Sqm__c = 3000, VBOT_Battery_Capacity_Wh__c = 150,
    VBOT_Has_GPS__c = true, VBOT_Has_Lawn_AI__c = true
));
productSpecs.put('VBOT_BAT_PLUS', new Product2(
    Name = 'VerdantBot High-Capacity Battery Pack', ProductCode = 'VBOT_BAT_PLUS',
    IsActive = true, Family = 'Accessory',
    VBOT_Tier_Label__c = 'Accessory',
    VBOT_Battery_Capacity_Wh__c = 130,
    VBOT_Has_GPS__c = false, VBOT_Has_Lawn_AI__c = false
));
productSpecs.put('VBOT_LAWN_AI', new Product2(
    Name = 'VerdantBot Lawn-AI Subscription', ProductCode = 'VBOT_LAWN_AI',
    IsActive = true, Family = 'Software',
    VBOT_Tier_Label__c = 'Software',
    VBOT_Has_GPS__c = false, VBOT_Has_Lawn_AI__c = true
));

Map<String, Id> productIdByCode = new Map<String, Id>();
for (Product2 existing : [
    SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :productSpecs.keySet()
]) {
    productIdByCode.put(existing.ProductCode, existing.Id);
}
List<Product2> productsToInsert = new List<Product2>();
for (String code : productSpecs.keySet()) {
    if (productIdByCode.containsKey(code)) {
        System.debug('[SKIP-EXISTS] Product ' + code + ' ' + productIdByCode.get(code));
    } else {
        productsToInsert.add(productSpecs.get(code));
    }
}
if (!productsToInsert.isEmpty()) {
    insert productsToInsert;
    for (Product2 p : productsToInsert) {
        productIdByCode.put(p.ProductCode, p.Id);
        System.debug('[CREATE] Product ' + p.ProductCode + ' ' + p.Id);
    }
}

// ---------------------------------------------------------------------------
// Block 4b: Hero-Image URLs (static-resource paths)
// ---------------------------------------------------------------------------
System.debug('--- Block 4b: Product hero images ---');
Map<String, String> imageMap = new Map<String, String>{
    'VBOT_E150'     => '/resource/vbot_e150',
    'VBOT_C300'     => '/resource/vbot_c300',
    'VBOT_C500'     => '/resource/vbot_c500',
    'VBOT_X800'     => '/resource/vbot_x800',
    'VBOT_BAT_PLUS' => '/resource/vbot_bat_plus',
    'VBOT_LAWN_AI'  => '/resource/vbot_lawn_ai'
};
List<Product2> imageUpdates = new List<Product2>();
for (Product2 p : [
    SELECT Id, ProductCode, VBOT_Hero_Image_Url__c
    FROM Product2 WHERE ProductCode LIKE 'VBOT_%'
]) {
    String expected = imageMap.get(p.ProductCode);
    if (expected != null && p.VBOT_Hero_Image_Url__c != expected) {
        p.VBOT_Hero_Image_Url__c = expected;
        imageUpdates.add(p);
    }
}
if (!imageUpdates.isEmpty()) {
    update imageUpdates;
    System.debug('[UPDATE] Product images: ' + imageUpdates.size() + ' records');
} else {
    System.debug('[SKIP-EXISTS] Product images already set');
}

// ---------------------------------------------------------------------------
// Block 5: PricebookEntry x 6 on standard pricebook
// ---------------------------------------------------------------------------
System.debug('--- Block 5: PricebookEntries ---');
Map<String, Decimal> priceByCode = new Map<String, Decimal>{
    'VBOT_E150' => 899, 'VBOT_C300' => 1499, 'VBOT_C500' => 1999,
    'VBOT_X800' => 2999, 'VBOT_BAT_PLUS' => 249, 'VBOT_LAWN_AI' => 49
};
Set<Id> existingPbeProductIds = new Set<Id>();
for (PricebookEntry pbe : [
    SELECT Id, Product2Id FROM PricebookEntry
    WHERE Pricebook2Id = :std.Id AND Product2Id IN :productIdByCode.values()
]) {
    existingPbeProductIds.add(pbe.Product2Id);
}
List<PricebookEntry> pbesToInsert = new List<PricebookEntry>();
for (String code : priceByCode.keySet()) {
    Id pid = productIdByCode.get(code);
    if (pid == null) { continue; }
    if (existingPbeProductIds.contains(pid)) {
        System.debug('[SKIP-EXISTS] PricebookEntry for ' + code);
    } else {
        pbesToInsert.add(new PricebookEntry(
            Pricebook2Id = std.Id, Product2Id = pid,
            UnitPrice = priceByCode.get(code), IsActive = true, UseStandardPrice = false
        ));
    }
}
if (!pbesToInsert.isEmpty()) {
    insert pbesToInsert;
    for (PricebookEntry pbe : pbesToInsert) {
        System.debug('[CREATE] PricebookEntry ' + pbe.Id);
    }
}

// ---------------------------------------------------------------------------
// Block 6: WarrantyTerm x 2
// ---------------------------------------------------------------------------
System.debug('--- Block 6: WarrantyTerms ---');
Map<String, WarrantyTerm> warrantyByName = new Map<String, WarrantyTerm>();
warrantyByName.put('VBOT 12M Software-Only', new WarrantyTerm(
    WarrantyTermName = 'VBOT 12M Software-Only',
    WarrantyType = 'Standard',
    EffectiveStartDate = 'Install Date',
    WarrantyDuration = 12, WarrantyUnitOfTime = 'Months'
));
warrantyByName.put('VBOT 24M Hardware Limited', new WarrantyTerm(
    WarrantyTermName = 'VBOT 24M Hardware Limited',
    WarrantyType = 'Standard',
    EffectiveStartDate = 'Install Date',
    WarrantyDuration = 24, WarrantyUnitOfTime = 'Months'
));
Set<String> existingWarrantyNames = new Set<String>();
for (WarrantyTerm wt : [
    SELECT WarrantyTermName FROM WarrantyTerm
    WHERE WarrantyTermName IN :warrantyByName.keySet()
]) { existingWarrantyNames.add(wt.WarrantyTermName); }
List<WarrantyTerm> wtsToInsert = new List<WarrantyTerm>();
for (String n : warrantyByName.keySet()) {
    if (existingWarrantyNames.contains(n)) {
        System.debug('[SKIP-EXISTS] WarrantyTerm ' + n);
    } else {
        wtsToInsert.add(warrantyByName.get(n));
    }
}
if (!wtsToInsert.isEmpty()) {
    insert wtsToInsert;
    for (WarrantyTerm wt : wtsToInsert) {
        System.debug('[CREATE] WarrantyTerm ' + wt.Id + ' ' + wt.WarrantyTermName);
    }
}

// ---------------------------------------------------------------------------
// Block 7: Asset "SN-2024-04711" (C300)
// ---------------------------------------------------------------------------
System.debug('--- Block 7: Asset ---');
Asset asset;
List<Asset> assets = [
    SELECT Id FROM Asset WHERE SerialNumber = 'SN-2024-04711' LIMIT 1
];
if (!assets.isEmpty()) {
    asset = assets[0];
    System.debug('[SKIP-EXISTS] Asset ' + asset.Id);
} else {
    asset = new Asset(
        Name = 'VerdantBot C300 #SN-2024-04711',
        SerialNumber = 'SN-2024-04711',
        AccountId = acc.Id, ContactId = con.Id,
        Product2Id = productIdByCode.get('VBOT_C300'),
        InstallDate = Date.today().addDays(-420),
        Status = 'Installed',
        VBOT_Property_Size_Sqm__c = 1200,
        VBOT_Battery_Health_Pct__c = 78,
        VBOT_Firmware_Version__c = '3.4.1',
        VBOT_Last_Sync__c = Datetime.now().addMinutes(-4),
        VBOT_Mobile_App_Enabled__c = true
    );
    insert asset;
    System.debug('[CREATE] Asset ' + asset.Id);
}

// ---------------------------------------------------------------------------
// Block 8: ServiceContract x 3
// ---------------------------------------------------------------------------
System.debug('--- Block 8: ServiceContracts ---');
Date installDate = Date.today().addDays(-420);
Date today = Date.today();

Map<String, ServiceContract> scByName = new Map<String, ServiceContract>();
scByName.put('VBOT VerdantCare Basic', new ServiceContract(
    Name = 'VBOT VerdantCare Basic',
    AccountId = acc.Id, ContactId = con.Id, Pricebook2Id = std.Id,
    StartDate = installDate, EndDate = installDate.addMonths(12),
    VBOT_Tier__c = 'Basic',
    VBOT_Monthly_Price__c = 4.99, VBOT_Yearly_Price__c = 49,
    VBOT_Covers_Hardware__c = false, VBOT_Covers_Software__c = true,
    VBOT_Covers_Battery__c = false, VBOT_Covers_Sensors__c = false,
    VBOT_Is_Template__c = false
));
scByName.put('VBOT VerdantCare Plus (Template)', new ServiceContract(
    Name = 'VBOT VerdantCare Plus (Template)',
    AccountId = acc.Id, ContactId = con.Id, Pricebook2Id = std.Id,
    StartDate = today, EndDate = today.addDays(365),
    VBOT_Tier__c = 'Plus',
    VBOT_Monthly_Price__c = 9.99, VBOT_Yearly_Price__c = 99,
    VBOT_Covers_Hardware__c = true, VBOT_Covers_Software__c = true,
    VBOT_Covers_Battery__c = true, VBOT_Covers_Sensors__c = true,
    VBOT_Is_Template__c = true
));
scByName.put('VBOT VerdantCare Premium (Template)', new ServiceContract(
    Name = 'VBOT VerdantCare Premium (Template)',
    AccountId = acc.Id, ContactId = con.Id, Pricebook2Id = std.Id,
    StartDate = today, EndDate = today.addDays(365),
    VBOT_Tier__c = 'Premium',
    VBOT_Monthly_Price__c = 14.99, VBOT_Yearly_Price__c = 149,
    VBOT_Covers_Hardware__c = true, VBOT_Covers_Software__c = true,
    VBOT_Covers_Battery__c = true, VBOT_Covers_Sensors__c = true,
    VBOT_Is_Template__c = true
));

Set<String> existingScNames = new Set<String>();
for (ServiceContract sc : [
    SELECT Name FROM ServiceContract WHERE Name IN :scByName.keySet()
]) { existingScNames.add(sc.Name); }
List<ServiceContract> scsToInsert = new List<ServiceContract>();
for (String n : scByName.keySet()) {
    if (existingScNames.contains(n)) {
        System.debug('[SKIP-EXISTS] ServiceContract ' + n);
    } else {
        scsToInsert.add(scByName.get(n));
    }
}
if (!scsToInsert.isEmpty()) {
    insert scsToInsert;
    for (ServiceContract sc : scsToInsert) {
        System.debug('[CREATE] ServiceContract ' + sc.Id + ' ' + sc.Name);
    }
}

// ---------------------------------------------------------------------------
// Block 9: WorkOrder
// ---------------------------------------------------------------------------
System.debug('--- Block 9: WorkOrder ---');
WorkOrder wo;
List<WorkOrder> wos = [
    SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'BATTERY_REPLACEMENT_001' LIMIT 1
];
if (!wos.isEmpty()) {
    wo = wos[0];
    System.debug('[SKIP-EXISTS] WorkOrder ' + wo.Id);
} else {
    wo = new WorkOrder(
        Subject = 'Lawn Mower not working - battery suspected',
        Status = 'In Progress',
        Priority = 'High',
        AssetId = asset.Id,
        AccountId = acc.Id,
        ContactId = con.Id,
        Pricebook2Id = std.Id,
        Description = 'Customer reports unit shuts down after 8 minutes of operation. Trunk inventory carries replacement battery.',
        VBOT_Demo_Scenario__c = 'BATTERY_REPLACEMENT_001',
        VBOT_Recommended_Action__c = 'Battery Replacement'
    );
    insert wo;
    System.debug('[CREATE] WorkOrder ' + wo.Id);
}

// ---------------------------------------------------------------------------
// Block 10: WorkOrderLineItem (battery pack)
// ---------------------------------------------------------------------------
System.debug('--- Block 10: WorkOrderLineItem ---');
Id batProductId = productIdByCode.get('VBOT_BAT_PLUS');
PricebookEntry batPbe = [
    SELECT Id FROM PricebookEntry
    WHERE Pricebook2Id = :std.Id AND Product2Id = :batProductId LIMIT 1
];
List<WorkOrderLineItem> woliExisting = [
    SELECT Id FROM WorkOrderLineItem
    WHERE WorkOrderId = :wo.Id AND Product2Id = :batProductId LIMIT 1
];
if (!woliExisting.isEmpty()) {
    System.debug('[SKIP-EXISTS] WorkOrderLineItem ' + woliExisting[0].Id);
} else {
    WorkOrderLineItem woli = new WorkOrderLineItem(
        WorkOrderId = wo.Id,
        PricebookEntryId = batPbe.Id,
        Quantity = 1,
        UnitPrice = 249,
        Status = 'In Progress'
    );
    insert woli;
    System.debug('[CREATE] WorkOrderLineItem ' + woli.Id);
}

// ---------------------------------------------------------------------------
// Block 11: VBOT_Asset_Telemetry__c x 30 (last 30 days), seeded RNG
// ---------------------------------------------------------------------------
System.debug('--- Block 11: AssetTelemetry ---');
List<VBOT_Asset_Telemetry__c> telemetry = new List<VBOT_Asset_Telemetry__c>();
String assetIdStr = String.valueOf(asset.Id).substring(0, 15);
Set<Integer> errorDays = new Set<Integer>{ 6, 17, 24 };
for (Integer i = 29; i >= 0; i--) {
    Datetime ts = Datetime.now().addDays(-i);
    String dayKey = ts.formatGmt('yyyyMMdd');
    String extId = 'TEL-' + assetIdStr + '-' + dayKey;

    Decimal batteryHealth = 92.0 - ((92.0 - 78.0) * Decimal.valueOf(29 - i) / 29.0);
    Integer dayHash = Math.mod(Math.abs(dayKey.hashCode()), 1000);
    Decimal mowedArea = 180 + Math.mod(dayHash, 181);
    Decimal opHours = (12 + Math.mod(dayHash * 7, 17)) / 10.0;
    Integer errorCount = errorDays.contains(i) ? (Math.mod(dayHash, 2) + 1) : 0;
    Integer lawnHealth = 68 + Math.mod(dayHash, 17);

    telemetry.add(new VBOT_Asset_Telemetry__c(
        VBOT_Asset__c = asset.Id,
        VBOT_Timestamp__c = ts,
        VBOT_External_Id__c = extId,
        VBOT_Battery_Health_Pct__c = batteryHealth.setScale(2, System.RoundingMode.HALF_UP),
        VBOT_Mowed_Area_Sqm__c = mowedArea,
        VBOT_Operating_Hours__c = opHours,
        VBOT_Error_Count__c = errorCount,
        VBOT_Firmware_Version__c = '3.4.1',
        VBOT_Lawn_Health_Score__c = lawnHealth
    ));
}
Schema.SObjectField extIdField =
    VBOT_Asset_Telemetry__c.fields.VBOT_External_Id__c;
Database.UpsertResult[] urs = Database.upsert(telemetry, extIdField, false);
Integer created = 0, updated = 0, failed = 0;
for (Database.UpsertResult r : urs) {
    if (!r.isSuccess()) { failed++; continue; }
    if (r.isCreated()) { created++; } else { updated++; }
}
System.debug('[UPSERT] Telemetry created=' + created + ' updated=' + updated + ' failed=' + failed);

System.debug('===== SEED COMPLETE =====');

} catch (Exception ex) {
    Database.rollback(sp);
    System.debug(LoggingLevel.ERROR, '[SEED FAILED] ' + ex.getTypeName() + ': ' + ex.getMessage());
    System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    throw ex;
}
