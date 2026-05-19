// =============================================================================
// VerdantBot Demo Reset Script
// =============================================================================
// Inverse of seed-vbot-demo.apex. Deletes all VBOT demo records in the order
// required by referential integrity. Metadata (custom fields, objects, layouts,
// permission sets) is left untouched.
// Run via:  sf apex run --file scripts/apex/reset-vbot-demo.apex \
//                       --target-org christopher.ramm@cap-de-mfg-awt-demo.com
// =============================================================================

Savepoint sp = Database.setSavepoint();
try {

// --- 1. Asset Telemetry --------------------------------------------------
System.debug('--- Reset 1: Asset Telemetry ---');
List<VBOT_Asset_Telemetry__c> tel = [
    SELECT Id FROM VBOT_Asset_Telemetry__c
    WHERE VBOT_Asset__r.SerialNumber = 'SN-2024-04711'
];
if (!tel.isEmpty()) {
    delete tel;
    System.debug('[DELETE] ' + tel.size() + ' telemetry rows');
} else {
    System.debug('[SKIP-EMPTY] no telemetry rows');
}

// --- 2. WorkOrderLineItems ----------------------------------------------
System.debug('--- Reset 2: WorkOrderLineItems ---');
List<WorkOrderLineItem> wolis = [
    SELECT Id FROM WorkOrderLineItem
    WHERE WorkOrder.VBOT_Demo_Scenario__c != null
];
if (!wolis.isEmpty()) {
    delete wolis;
    System.debug('[DELETE] ' + wolis.size() + ' work order line items');
} else {
    System.debug('[SKIP-EMPTY] no work order line items');
}

// --- 3. WorkOrder --------------------------------------------------------
System.debug('--- Reset 3: WorkOrders ---');
List<WorkOrder> wos = [
    SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c != null
];
if (!wos.isEmpty()) {
    delete wos;
    System.debug('[DELETE] ' + wos.size() + ' work orders');
} else {
    System.debug('[SKIP-EMPTY] no work orders');
}

// --- 4. ServiceContracts ------------------------------------------------
System.debug('--- Reset 4: ServiceContracts ---');
List<ServiceContract> scs = [
    SELECT Id FROM ServiceContract WHERE Name LIKE 'VBOT %'
];
if (!scs.isEmpty()) {
    delete scs;
    System.debug('[DELETE] ' + scs.size() + ' service contracts');
} else {
    System.debug('[SKIP-EMPTY] no service contracts');
}

// --- 5. Asset ------------------------------------------------------------
System.debug('--- Reset 5: Asset ---');
List<Asset> assets = [SELECT Id FROM Asset WHERE SerialNumber = 'SN-2024-04711'];
if (!assets.isEmpty()) {
    delete assets;
    System.debug('[DELETE] Asset ' + assets[0].Id);
} else {
    System.debug('[SKIP-EMPTY] no asset');
}

// --- 6. WarrantyTerms ---------------------------------------------------
System.debug('--- Reset 6: WarrantyTerms ---');
List<WarrantyTerm> wts = [
    SELECT Id FROM WarrantyTerm WHERE WarrantyTermName LIKE 'VBOT %'
];
if (!wts.isEmpty()) {
    delete wts;
    System.debug('[DELETE] ' + wts.size() + ' warranty terms');
} else {
    System.debug('[SKIP-EMPTY] no warranty terms');
}

// --- 7. PricebookEntries (only those on VBOT products) ------------------
System.debug('--- Reset 7: PricebookEntries ---');
List<PricebookEntry> pbes = [
    SELECT Id FROM PricebookEntry WHERE Product2.ProductCode LIKE 'VBOT%'
];
if (!pbes.isEmpty()) {
    delete pbes;
    System.debug('[DELETE] ' + pbes.size() + ' pricebook entries');
} else {
    System.debug('[SKIP-EMPTY] no pricebook entries');
}

// --- 8. Products ---------------------------------------------------------
System.debug('--- Reset 8: Products ---');
List<Product2> prods = [
    SELECT Id FROM Product2 WHERE ProductCode LIKE 'VBOT%'
];
if (!prods.isEmpty()) {
    delete prods;
    System.debug('[DELETE] ' + prods.size() + ' products');
} else {
    System.debug('[SKIP-EMPTY] no products');
}

// --- 9. Contact ----------------------------------------------------------
System.debug('--- Reset 9: Contact ---');
List<Contact> cons = [SELECT Id FROM Contact WHERE Email = 'anna.schmidt@example.vbot'];
if (!cons.isEmpty()) {
    delete cons;
    System.debug('[DELETE] Contact ' + cons[0].Id);
} else {
    System.debug('[SKIP-EMPTY] no contact');
}

// --- 10. Account --------------------------------------------------------
System.debug('--- Reset 10: Account ---');
List<Account> accs = [SELECT Id FROM Account WHERE Name = 'VBOT Familie Schmidt'];
if (!accs.isEmpty()) {
    delete accs;
    System.debug('[DELETE] Account ' + accs[0].Id);
} else {
    System.debug('[SKIP-EMPTY] no account');
}

System.debug('===== RESET COMPLETE =====');

} catch (Exception ex) {
    Database.rollback(sp);
    System.debug(LoggingLevel.ERROR, '[RESET FAILED] ' + ex.getTypeName() + ': ' + ex.getMessage());
    System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    throw ex;
}
