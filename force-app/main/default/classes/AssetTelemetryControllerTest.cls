@isTest
private class AssetTelemetryControllerTest {

    @testSetup
    static void setupData() {
        Account a = new Account(
            Name = 'VBOT Familie Telemetry',
            BillingCity = 'Berlin', BillingCountry = 'DE', Type = 'Customer'
        );
        insert a;

        Product2 p = new Product2(
            Name = 'VerdantBot C300', ProductCode = 'VBOT_C300', IsActive = true,
            VBOT_Tier_Label__c = 'Comfort'
        );
        insert p;

        Asset ast = new Asset(
            Name = 'VerdantBot C300 #TEL-001',
            SerialNumber = 'TEL-001', AccountId = a.Id, Product2Id = p.Id,
            InstallDate = Date.today().addDays(-420), Status = 'Installed',
            VBOT_Property_Size_Sqm__c = 1200,
            VBOT_Battery_Health_Pct__c = 78,
            VBOT_Firmware_Version__c = '3.4.1',
            VBOT_Last_Sync__c = Datetime.now().addMinutes(-4),
            VBOT_Mobile_App_Enabled__c = true
        );
        insert ast;

        insert new ServiceContract(
            Name = 'VBOT VerdantCare Basic',
            AccountId = a.Id,
            StartDate = Date.today().addDays(-30),
            EndDate = Date.today().addDays(60),
            VBOT_Tier__c = 'Basic',
            VBOT_Monthly_Price__c = 4.99,
            VBOT_Yearly_Price__c = 49,
            VBOT_Covers_Software__c = true,
            VBOT_Is_Template__c = false
        );

        List<VBOT_Asset_Telemetry__c> rows = new List<VBOT_Asset_Telemetry__c>();
        for (Integer i = 29; i >= 0; i--) {
            Datetime ts = Datetime.now().addDays(-i);
            rows.add(new VBOT_Asset_Telemetry__c(
                VBOT_Asset__c = ast.Id,
                VBOT_Timestamp__c = ts,
                VBOT_External_Id__c = 'TEL-TEST-' + i,
                VBOT_Battery_Health_Pct__c = (92 - (14.0 * (29 - i) / 29.0)),
                VBOT_Mowed_Area_Sqm__c = 200 + Math.mod(i * 17, 160),
                VBOT_Operating_Hours__c = 1.5,
                VBOT_Error_Count__c = i == 17 ? 2 : 0,
                VBOT_Firmware_Version__c = '3.4.1',
                VBOT_Lawn_Health_Score__c = 70 + Math.mod(i * 3, 15)
            ));
        }
        insert rows;
    }

    @isTest
    static void happyPath_returnsFullDto() {
        Asset a = [SELECT Id FROM Asset WHERE SerialNumber = 'TEL-001' LIMIT 1];
        Test.startTest();
        AssetTelemetryController.DashboardDataDTO dto =
            AssetTelemetryController.getDashboardData(a.Id, '30d');
        Test.stopTest();

        System.assertNotEquals(null, dto.asset);
        System.assertEquals('VerdantBot C300 #TEL-001', dto.asset.name);
        System.assertEquals(1200, dto.asset.propertySize);
        System.assertEquals(4, dto.kpis.size(), 'Four KPI tiles always');
        System.assertEquals(30, dto.timeline.size(), '30 timeline points for 30d');
        System.assertEquals(4, dto.lawnZones.size(), 'Four lawn zones static');
        System.assertNotEquals(null, dto.forecast);
        System.assertNotEquals(null, dto.mobileMirror);
        System.assertNotEquals(null, dto.mobileMirror.lawnZones);
        System.assertEquals(4, dto.mobileMirror.lawnZones.size(),
            'MobileMirror reuses same zones');
        System.assertEquals('VBOT VerdantCare Basic', dto.mobileMirror.contractName);
    }

    @isTest
    static void range7d_returnsSevenPoints() {
        Asset a = [SELECT Id FROM Asset WHERE SerialNumber = 'TEL-001' LIMIT 1];
        Test.startTest();
        AssetTelemetryController.DashboardDataDTO dto =
            AssetTelemetryController.getDashboardData(a.Id, '7d');
        Test.stopTest();
        System.assertEquals(7, dto.timeline.size());
    }

    @isTest
    static void range90d_synthesisesBackward() {
        Asset a = [SELECT Id FROM Asset WHERE SerialNumber = 'TEL-001' LIMIT 1];
        Test.startTest();
        AssetTelemetryController.DashboardDataDTO dto =
            AssetTelemetryController.getDashboardData(a.Id, '90d');
        Test.stopTest();
        System.assertEquals(90, dto.timeline.size(),
            '60 extrapolated + 30 real');
    }

    @isTest
    static void assetWithoutTelemetry_returnsGracefulDefaults() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Asset bare = new Asset(
            Name = 'Bare Asset', SerialNumber = 'BARE-001',
            AccountId = a.Id, Status = 'Installed'
        );
        insert bare;

        Test.startTest();
        AssetTelemetryController.DashboardDataDTO dto =
            AssetTelemetryController.getDashboardData(bare.Id, '30d');
        Test.stopTest();

        System.assertEquals(0, dto.timeline.size());
        System.assertEquals(4, dto.lawnZones.size());
        System.assertEquals(0, dto.forecast.daysUntil);
    }

    @isTest
    static void nullAssetId_throws() {
        Test.startTest();
        try {
            AssetTelemetryController.getDashboardData(null, '30d');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException ex) { /* expected */ }
        Test.stopTest();
    }
}
