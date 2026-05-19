@isTest
private class ProductUpgradeControllerTest {

    @testSetup
    static void setupData() {
        Account a = new Account(
            Name = 'VBOT Familie Testkunde',
            BillingCity = 'Berlin', BillingCountry = 'DE',
            Type = 'Customer'
        );
        insert a;

        Contact c = new Contact(
            FirstName = 'Anna', LastName = 'Testkunde',
            AccountId = a.Id,
            Email = 'anna@test.vbot'
        );
        insert c;

        List<Product2> products = new List<Product2>{
            new Product2(Name = 'VerdantBot C300', ProductCode = 'VBOT_C300',
                IsActive = true, VBOT_Tier_Label__c = 'Comfort',
                VBOT_Max_Area_Sqm__c = 1000, VBOT_Battery_Capacity_Wh__c = 90,
                VBOT_Has_GPS__c = false, VBOT_Has_Lawn_AI__c = false),
            new Product2(Name = 'VerdantBot C500', ProductCode = 'VBOT_C500',
                IsActive = true, VBOT_Tier_Label__c = 'Comfort+',
                VBOT_Max_Area_Sqm__c = 1500, VBOT_Battery_Capacity_Wh__c = 110),
            new Product2(Name = 'VerdantBot X800', ProductCode = 'VBOT_X800',
                IsActive = true, VBOT_Tier_Label__c = 'Pro',
                VBOT_Max_Area_Sqm__c = 3000, VBOT_Battery_Capacity_Wh__c = 150,
                VBOT_Has_GPS__c = true, VBOT_Has_Lawn_AI__c = true),
            new Product2(Name = 'VerdantBot High-Capacity Battery Pack',
                ProductCode = 'VBOT_BAT_PLUS', IsActive = true,
                VBOT_Tier_Label__c = 'Accessory',
                VBOT_Battery_Capacity_Wh__c = 130)
        };
        insert products;

        Id stdId = Test.getStandardPricebookId();
        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 p : products) {
            entries.add(new PricebookEntry(
                Pricebook2Id = stdId, Product2Id = p.Id,
                UnitPrice = 1000, IsActive = true, UseStandardPrice = false
            ));
        }
        insert entries;

        Product2 c300 = products[0];
        Asset ast = new Asset(
            Name = 'VerdantBot C300 #TEST',
            SerialNumber = 'TEST-UP-001',
            AccountId = a.Id, ContactId = c.Id, Product2Id = c300.Id,
            InstallDate = Date.today().addDays(-420), Status = 'Installed',
            VBOT_Property_Size_Sqm__c = 1200,
            VBOT_Battery_Health_Pct__c = 78,
            VBOT_Firmware_Version__c = '3.4.1'
        );
        insert ast;

        insert new WorkOrder(
            Subject = 'Test upgrade WO', Status = 'New',
            AccountId = a.Id, ContactId = c.Id, AssetId = ast.Id,
            VBOT_Demo_Scenario__c = 'UPGRADE_TEST'
        );
    }

    @isTest
    static void happyPath_threeOptions_middleIsRecommended() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'UPGRADE_TEST' LIMIT 1];

        Test.startTest();
        ProductUpgradeController.UpgradeStudioDataDTO dto =
            ProductUpgradeController.getUpgradeData(wo.Id);
        Test.stopTest();

        System.assertEquals('VerdantBot C300 #TEST', dto.asset.name);
        System.assertEquals(1200, dto.asset.propertySize);
        System.assertEquals(3, dto.options.size(), 'Three upgrade options');

        Map<String, ProductUpgradeController.ProductUpgradeOptionDTO> byCode =
            new Map<String, ProductUpgradeController.ProductUpgradeOptionDTO>();
        for (ProductUpgradeController.ProductUpgradeOptionDTO o : dto.options) {
            byCode.put(o.productCode, o);
        }
        System.assert(byCode.containsKey('VBOT_BAT_PLUS'));
        System.assert(byCode.containsKey('VBOT_C500'));
        System.assert(byCode.containsKey('VBOT_X800'));
        System.assert(byCode.get('VBOT_C500').isRecommended,
            'Comfort+ must be recommended');
        System.assertEquals(86, byCode.get('VBOT_C500').fitScore);

        Boolean foundGrowth = false;
        for (ProductUpgradeController.ReasoningBulletDTO b : dto.reasoning.bullets) {
            if (b.text != null && b.text.contains('Mähkapazität')) foundGrowth = true;
        }
        System.assert(foundGrowth, 'Reasoning should mention growth when property exceeds capacity');
    }

    @isTest
    static void assetWithoutPropertySize_fallsBackReasoning() {
        Asset a = [SELECT Id FROM Asset WHERE SerialNumber = 'TEST-UP-001' LIMIT 1];
        a.VBOT_Property_Size_Sqm__c = null;
        update a;
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'UPGRADE_TEST' LIMIT 1];

        Test.startTest();
        ProductUpgradeController.UpgradeStudioDataDTO dto =
            ProductUpgradeController.getUpgradeData(wo.Id);
        Test.stopTest();

        Boolean fallbackBulletPresent = false;
        for (ProductUpgradeController.ReasoningBulletDTO b : dto.reasoning.bullets) {
            if (b.text != null && b.text.contains('Grundstücksgröße unbekannt')) {
                fallbackBulletPresent = true;
            }
        }
        System.assert(fallbackBulletPresent, 'Fallback reasoning bullet must be present');
        System.assertEquals(null, dto.asset.propertySize);
    }

    @isTest
    static void nullId_throws() {
        Test.startTest();
        try {
            ProductUpgradeController.getUpgradeData(null);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException ex) { /* expected */ }
        Test.stopTest();
    }

    @isTest
    static void workOrderWithoutAsset_throws() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        WorkOrder bare = new WorkOrder(
            Subject = 'No asset', Status = 'New',
            AccountId = a.Id,
            VBOT_Demo_Scenario__c = 'NO_ASSET'
        );
        insert bare;

        Test.startTest();
        try {
            ProductUpgradeController.getUpgradeData(bare.Id);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException ex) { /* expected */ }
        Test.stopTest();
    }

    @isTest
    static void missingWorkOrder_throws() {
        Test.startTest();
        try {
            ProductUpgradeController.getUpgradeData('08q000000000000AAA');
            System.assert(false, 'Should have thrown');
        } catch (Exception ex) { /* AuraHandled or invalid id */ }
        Test.stopTest();
    }
}
