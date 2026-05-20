@isTest
private class DemoResetControllerTest {

    @testSetup
    static void setupData() {
        Account a = new Account(
            Name = 'VBOT Reset Testkunde',
            BillingCity = 'Berlin', BillingCountry = 'DE', Type = 'Customer'
        );
        insert a;

        Product2 p = new Product2(
            Name = 'VerdantBot C300', ProductCode = 'VBOT_C300', IsActive = true,
            VBOT_Tier_Label__c = 'Comfort'
        );
        insert p;

        Asset ast = new Asset(
            Name = 'VerdantBot C300 #RST-001',
            SerialNumber = 'RST-001', AccountId = a.Id, Product2Id = p.Id,
            InstallDate = Date.today().addDays(-400), Status = 'Installed',
            VBOT_Property_Size_Sqm__c = 1200,
            VBOT_Battery_Health_Pct__c = 78,
            VBOT_Firmware_Version__c = '3.4.1'
        );
        insert ast;

        insert new WorkOrder(
            Subject = 'Reset test', Status = 'Completed',
            AccountId = a.Id, AssetId = ast.Id,
            VBOT_Demo_Scenario__c = 'RESET_TEST',
            VBOT_Recommended_Action__c = 'None'
        );

        insert new ServiceContract(
            Name = 'VBOT VerdantCare Basic',
            AccountId = a.Id,
            StartDate = Date.today().addDays(-60),
            EndDate = Date.today().addDays(-10),
            VBOT_Tier__c = 'Basic',
            VBOT_Monthly_Price__c = 4.99,
            VBOT_Yearly_Price__c = 49,
            VBOT_Covers_Software__c = true,
            VBOT_Is_Template__c = false
        );
    }

    @isTest
    static void resetsStatusAndTelemetryAndContract() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'RESET_TEST' LIMIT 1];

        Test.startTest();
        String result = DemoResetController.resetWorkOrderDemo(wo.Id);
        Test.stopTest();

        System.assert(result != null && result.contains('zurückgesetzt'));

        WorkOrder reloaded = [SELECT Status, VBOT_Recommended_Action__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('In Progress', reloaded.Status);
        System.assertEquals('Battery Replacement', reloaded.VBOT_Recommended_Action__c);

        Integer tel = [SELECT COUNT() FROM VBOT_Asset_Telemetry__c WHERE VBOT_Asset__r.SerialNumber = 'RST-001'];
        System.assertEquals(7, tel, 'Reset re-seeds exactly 7 telemetry rows');

        ServiceContract sc = [SELECT EndDate FROM ServiceContract WHERE VBOT_Tier__c = 'Basic' LIMIT 1];
        System.assert(sc.EndDate >= Date.today(),
            'Basic contract end date must be pushed back to a future date');
    }

    @isTest
    static void idempotent_secondRunStillSeven() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'RESET_TEST' LIMIT 1];

        Test.startTest();
        DemoResetController.resetWorkOrderDemo(wo.Id);
        DemoResetController.resetWorkOrderDemo(wo.Id);
        Test.stopTest();

        Integer tel = [SELECT COUNT() FROM VBOT_Asset_Telemetry__c WHERE VBOT_Asset__r.SerialNumber = 'RST-001'];
        System.assertEquals(7, tel, 'Second reset must not produce duplicates');
    }

    @isTest
    static void nullId_throws() {
        Test.startTest();
        try {
            DemoResetController.resetWorkOrderDemo(null);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException ex) { /* expected */ }
        Test.stopTest();
    }
}
