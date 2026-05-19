/**
 * VerdantBot demo Apex controller for the warrantyAdvisorPanel LWC.
 *
 * Reads VBOT_*__c fields off ServiceContract / Asset / WorkOrder, then
 * returns a fully-shaped DTO ready for the wireframe. Read-only — confirm
 * upgrade is a toast, no DML.
 */
public with sharing class WarrantyAdvisorController {

    private static final Set<String> ACTIVE_TIER_FILTER = new Set<String>{ 'Plus', 'Premium' };

    @AuraEnabled(cacheable=true)
    public static AdvisorDataDTO getAdvisorData(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('WorkOrder id is required.');
        }

        List<WorkOrder> wos = [
            SELECT Id, AccountId, AssetId, Asset.Name, Account.Name
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        if (wos.isEmpty()) {
            throw new AuraHandledException('WorkOrder not found.');
        }
        WorkOrder wo = wos[0];
        if (wo.AccountId == null) {
            throw new AuraHandledException('WorkOrder has no Account.');
        }

        List<ServiceContract> contracts = [
            SELECT Id, Name, ContractNumber, StartDate, EndDate,
                   VBOT_Tier__c, VBOT_Monthly_Price__c, VBOT_Yearly_Price__c,
                   VBOT_Covers_Hardware__c, VBOT_Covers_Software__c,
                   VBOT_Covers_Battery__c, VBOT_Covers_Sensors__c,
                   VBOT_Is_Template__c
            FROM ServiceContract
            WHERE AccountId = :wo.AccountId AND Name LIKE 'VBOT %'
            ORDER BY VBOT_Is_Template__c ASC, VBOT_Tier__c ASC
        ];

        ServiceContract active;
        List<ServiceContract> templates = new List<ServiceContract>();
        for (ServiceContract sc : contracts) {
            if (sc.VBOT_Is_Template__c == false && active == null) {
                active = sc;
            } else if (sc.VBOT_Is_Template__c == true) {
                templates.add(sc);
            }
        }

        AdvisorDataDTO dto = new AdvisorDataDTO();
        dto.assetName = wo.Asset != null ? wo.Asset.Name : 'Unknown asset';
        dto.accountName = wo.Account != null ? wo.Account.Name : 'Unknown customer';

        if (active != null) {
            CurrentContractDTO cur = new CurrentContractDTO();
            cur.contractId = active.Id;
            cur.name = active.Name;
            cur.tier = active.VBOT_Tier__c;
            cur.endDate = active.EndDate;
            dto.currentContract = cur;
        }

        dto.coverages = buildCoverages(active);
        dto.options = buildOptions(active, templates);

        return dto;
    }

    private static List<CoverageItemDTO> buildCoverages(ServiceContract active) {
        Boolean coversSoftware = active != null && active.VBOT_Covers_Software__c == true;
        Boolean coversBattery = active != null && active.VBOT_Covers_Battery__c == true;
        Boolean coversHardware = active != null && active.VBOT_Covers_Hardware__c == true;
        Boolean coversSensors = active != null && active.VBOT_Covers_Sensors__c == true;

        Integer daysToExpiry = null;
        if (active != null && active.EndDate != null) {
            daysToExpiry = Date.today().daysBetween(active.EndDate);
        }
        Boolean softwareExpiring = coversSoftware && daysToExpiry != null && daysToExpiry < 90;
        Boolean hardwarePartial = !coversHardware && active != null && active.VBOT_Tier__c == 'Basic';

        List<CoverageItemDTO> result = new List<CoverageItemDTO>();
        result.add(coverage('software', 'Software & App',
            softwareExpiring ? 'expiring' : (coversSoftware ? 'covered' : 'uncovered'),
            softwareExpiring ? daysToExpiry : null
        ));
        result.add(coverage('battery', 'Akku',
            coversBattery ? 'covered' : 'uncovered', null));
        result.add(coverage('hardware', 'Hardware',
            coversHardware ? 'covered' : (hardwarePartial ? 'partial' : 'uncovered'), null));
        result.add(coverage('sensors', 'Sensorik',
            coversSensors ? 'covered' : 'uncovered', null));
        return result;
    }

    private static CoverageItemDTO coverage(String key, String label, String status, Integer days) {
        CoverageItemDTO c = new CoverageItemDTO();
        c.key = key;
        c.label = label;
        c.status = status;
        c.expiresInDays = days;
        return c;
    }

    private static List<ContractOptionDTO> buildOptions(ServiceContract active, List<ServiceContract> templates) {
        List<ContractOptionDTO> result = new List<ContractOptionDTO>();
        if (active != null) {
            result.add(toOption(active, false, 'Aktiver Vertrag'));
        }
        for (ServiceContract t : templates) {
            Boolean isRecommended = (t.VBOT_Tier__c == 'Plus');
            String cta = isRecommended ? 'Auf Plus upgraden' : 'Auf Premium upgraden';
            result.add(toOption(t, isRecommended, cta));
        }
        return result;
    }

    private static ContractOptionDTO toOption(ServiceContract sc, Boolean isRecommended, String cta) {
        ContractOptionDTO o = new ContractOptionDTO();
        o.contractId = sc.Id;
        o.tier = sc.VBOT_Tier__c;
        o.name = sc.Name;
        o.monthlyPrice = sc.VBOT_Monthly_Price__c;
        o.yearlyPrice = sc.VBOT_Yearly_Price__c;
        o.isRecommended = isRecommended;
        o.ctaLabel = cta;
        o.coverages = new List<CoverageItemDTO>();
        o.coverages.add(coverage('software', 'Software & App',
            sc.VBOT_Covers_Software__c == true ? 'covered' : 'uncovered', null));
        o.coverages.add(coverage('battery', 'Akku',
            sc.VBOT_Covers_Battery__c == true ? 'covered' : 'uncovered', null));
        o.coverages.add(coverage('hardware', 'Hardware',
            sc.VBOT_Covers_Hardware__c == true ? 'covered' : 'uncovered', null));
        o.coverages.add(coverage('sensors', 'Sensorik',
            sc.VBOT_Covers_Sensors__c == true ? 'covered' : 'uncovered', null));
        return o;
    }

    public class AdvisorDataDTO {
        @AuraEnabled public String assetName;
        @AuraEnabled public String accountName;
        @AuraEnabled public CurrentContractDTO currentContract;
        @AuraEnabled public List<CoverageItemDTO> coverages;
        @AuraEnabled public List<ContractOptionDTO> options;
    }

    public class CurrentContractDTO {
        @AuraEnabled public Id contractId;
        @AuraEnabled public String name;
        @AuraEnabled public String tier;
        @AuraEnabled public Date endDate;
    }

    public class CoverageItemDTO {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String status;
        @AuraEnabled public Integer expiresInDays;
    }

    public class ContractOptionDTO {
        @AuraEnabled public Id contractId;
        @AuraEnabled public String tier;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal monthlyPrice;
        @AuraEnabled public Decimal yearlyPrice;
        @AuraEnabled public Boolean isRecommended;
        @AuraEnabled public List<CoverageItemDTO> coverages;
        @AuraEnabled public String ctaLabel;
    }
}
