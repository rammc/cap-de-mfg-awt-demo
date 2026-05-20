/**
 * Demo reset called from the demoResetAction quick action LWC.
 * Idempotent: rewinds WorkOrder status + recommended action, re-seeds the
 * last 7 telemetry rows for the asset, and reactivates the Basic contract.
 */
public with sharing class DemoResetController {

    @AuraEnabled
    public static String resetWorkOrderDemo(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('WorkOrder id is required.');
        }
        Savepoint sp = Database.setSavepoint();
        try {
            List<WorkOrder> wos = [
                SELECT Id, Status, VBOT_Recommended_Action__c, AssetId, AccountId
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            if (wos.isEmpty()) {
                throw new AuraHandledException('WorkOrder not found.');
            }
            WorkOrder wo = wos[0];
            wo.Status = 'In Progress';
            wo.VBOT_Recommended_Action__c = 'Battery Replacement';
            update wo;

            if (wo.AssetId != null) {
                resetTelemetry(wo.AssetId);
            }

            if (wo.AccountId != null) {
                reactivateBasic(wo.AccountId);
            }

            return 'Demo-Daten zurückgesetzt.';
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static void resetTelemetry(Id assetId) {
        List<VBOT_Asset_Telemetry__c> rows = [
            SELECT Id FROM VBOT_Asset_Telemetry__c
            WHERE VBOT_Asset__c = :assetId
            ORDER BY VBOT_Timestamp__c DESC
            LIMIT 7
        ];
        if (!rows.isEmpty()) {
            delete rows;
        }
        String assetIdStr = String.valueOf(assetId).substring(0, 15);
        List<VBOT_Asset_Telemetry__c> reseeded = new List<VBOT_Asset_Telemetry__c>();
        for (Integer i = 6; i >= 0; i--) {
            Datetime ts = Datetime.now().addDays(-i);
            String dayKey = ts.formatGmt('yyyyMMdd');
            Integer hash = Math.abs(dayKey.hashCode());
            Decimal battery = 84 - (Decimal.valueOf(6 - i) / 6) * 4;
            reseeded.add(new VBOT_Asset_Telemetry__c(
                VBOT_Asset__c = assetId,
                VBOT_Timestamp__c = ts,
                VBOT_External_Id__c = 'TEL-' + assetIdStr + '-' + dayKey,
                VBOT_Battery_Health_Pct__c = battery.setScale(2, System.RoundingMode.HALF_UP),
                VBOT_Mowed_Area_Sqm__c = 200 + Math.mod(hash, 181),
                VBOT_Operating_Hours__c = (12 + Math.mod(hash * 7, 17)) / 10.0,
                VBOT_Error_Count__c = 0,
                VBOT_Firmware_Version__c = '3.4.1',
                VBOT_Lawn_Health_Score__c = 70 + Math.mod(hash, 17)
            ));
        }
        Schema.SObjectField extIdField =
            VBOT_Asset_Telemetry__c.fields.VBOT_External_Id__c;
        Database.upsert(reseeded, extIdField, false);
    }

    private static void reactivateBasic(Id accountId) {
        List<ServiceContract> basics = [
            SELECT Id, StartDate, EndDate
            FROM ServiceContract
            WHERE AccountId = :accountId
              AND VBOT_Tier__c = 'Basic'
              AND VBOT_Is_Template__c = false
            LIMIT 1
        ];
        if (basics.isEmpty()) return;
        ServiceContract sc = basics[0];
        Date today = Date.today();
        if (sc.EndDate == null || sc.EndDate < today) {
            sc.EndDate = today.addMonths(12);
        }
        if (sc.StartDate == null) {
            sc.StartDate = today.addMonths(-12);
        }
        update sc;
    }
}
