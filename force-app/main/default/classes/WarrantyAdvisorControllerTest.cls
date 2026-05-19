@isTest
private class WarrantyAdvisorControllerTest {

    @testSetup
    static void setupData() {
        Account a = new Account(
            Name = 'VBOT Familie Testkunde',
            BillingCity = 'Berlin', BillingCountry = 'DE',
            Type = 'Customer'
        );
        insert a;

        Product2 p = new Product2(
            Name = 'VerdantBot C300',
            ProductCode = 'VBOT_C300',
            IsActive = true,
            VBOT_Tier_Label__c = 'Comfort'
        );
        insert p;

        Asset ast = new Asset(
            Name = 'VerdantBot C300 #TEST-001',
            SerialNumber = 'TEST-001',
            AccountId = a.Id,
            Product2Id = p.Id,
            Status = 'Installed',
            VBOT_Property_Size_Sqm__c = 1200,
            VBOT_Battery_Health_Pct__c = 80
        );
        insert ast;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            AccountId = a.Id,
            AssetId = ast.Id,
            VBOT_Demo_Scenario__c = 'TEST_SCENARIO'
        );
        insert wo;

        Date today = Date.today();
        List<ServiceContract> contracts = new List<ServiceContract>{
            new ServiceContract(
                Name = 'VBOT VerdantCare Basic',
                AccountId = a.Id,
                StartDate = today.addDays(-30),
                EndDate = today.addDays(60),
                VBOT_Tier__c = 'Basic',
                VBOT_Monthly_Price__c = 4.99,
                VBOT_Yearly_Price__c = 49,
                VBOT_Covers_Software__c = true,
                VBOT_Covers_Battery__c = false,
                VBOT_Covers_Hardware__c = false,
                VBOT_Covers_Sensors__c = false,
                VBOT_Is_Template__c = false
            ),
            new ServiceContract(
                Name = 'VBOT VerdantCare Plus (Template)',
                AccountId = a.Id,
                StartDate = today,
                EndDate = today.addDays(365),
                VBOT_Tier__c = 'Plus',
                VBOT_Monthly_Price__c = 9.99,
                VBOT_Yearly_Price__c = 99,
                VBOT_Covers_Software__c = true,
                VBOT_Covers_Battery__c = true,
                VBOT_Covers_Hardware__c = true,
                VBOT_Covers_Sensors__c = true,
                VBOT_Is_Template__c = true
            ),
            new ServiceContract(
                Name = 'VBOT VerdantCare Premium (Template)',
                AccountId = a.Id,
                StartDate = today,
                EndDate = today.addDays(365),
                VBOT_Tier__c = 'Premium',
                VBOT_Monthly_Price__c = 14.99,
                VBOT_Yearly_Price__c = 149,
                VBOT_Covers_Software__c = true,
                VBOT_Covers_Battery__c = true,
                VBOT_Covers_Hardware__c = true,
                VBOT_Covers_Sensors__c = true,
                VBOT_Is_Template__c = true
            )
        };
        insert contracts;
    }

    @isTest
    static void happyPath_returnsFullDto() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'TEST_SCENARIO' LIMIT 1];

        Test.startTest();
        WarrantyAdvisorController.AdvisorDataDTO dto =
            WarrantyAdvisorController.getAdvisorData(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO must not be null');
        System.assertEquals('VerdantBot C300 #TEST-001', dto.assetName);
        System.assertEquals('VBOT Familie Testkunde', dto.accountName);

        System.assertNotEquals(null, dto.currentContract, 'Active contract must be returned');
        System.assertEquals('Basic', dto.currentContract.tier);

        System.assertEquals(4, dto.coverages.size(), 'Always four coverage items');
        Map<String, String> statusByKey = new Map<String, String>();
        for (WarrantyAdvisorController.CoverageItemDTO c : dto.coverages) {
            statusByKey.put(c.key, c.status);
        }
        System.assertEquals('expiring', statusByKey.get('software'),
            'Basic ends in 60d so software is expiring');
        System.assertEquals('uncovered', statusByKey.get('battery'));
        System.assertEquals('partial', statusByKey.get('hardware'),
            'Basic tier means hardware should be flagged partial');
        System.assertEquals('uncovered', statusByKey.get('sensors'));

        System.assertEquals(3, dto.options.size(),
            'Active + Plus template + Premium template');
        Boolean plusFound = false;
        for (WarrantyAdvisorController.ContractOptionDTO opt : dto.options) {
            if (opt.tier == 'Plus') {
                plusFound = true;
                System.assert(opt.isRecommended, 'Plus must be marked recommended');
            }
        }
        System.assert(plusFound, 'Plus option must be present');
    }

    @isTest
    static void nullId_throws() {
        Test.startTest();
        try {
            WarrantyAdvisorController.getAdvisorData(null);
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException ex) {
            // expected
        }
        Test.stopTest();
    }

    @isTest
    static void missingWorkOrder_throws() {
        Test.startTest();
        try {
            WarrantyAdvisorController.getAdvisorData('08q000000000000AAA');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException ex) {
            // expected
        } catch (System.StringException ex) {
            // invalid id format also acceptable
        }
        Test.stopTest();
    }

    @isTest
    static void noActiveContract_returnsTemplatesOnly() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder WHERE VBOT_Demo_Scenario__c = 'TEST_SCENARIO' LIMIT 1];
        delete [SELECT Id FROM ServiceContract WHERE AccountId = :wo.AccountId AND VBOT_Is_Template__c = false];

        Test.startTest();
        WarrantyAdvisorController.AdvisorDataDTO dto =
            WarrantyAdvisorController.getAdvisorData(wo.Id);
        Test.stopTest();

        System.assertEquals(null, dto.currentContract);
        System.assertEquals(2, dto.options.size(), 'Only Plus + Premium templates');
        for (WarrantyAdvisorController.CoverageItemDTO c : dto.coverages) {
            System.assertEquals('uncovered', c.status,
                'Without active contract every coverage is uncovered');
        }
    }
}
