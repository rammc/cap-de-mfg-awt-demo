/**
 * VerdantBot demo Apex controller for the productUpgradeStudio LWC.
 *
 * Loads WorkOrder → Asset → current Product2, then assembles three upgrade
 * candidates (Battery accessory, Comfort+ model upgrade, Pro model upgrade)
 * with reasoning bullets derived from asset context. Read-only.
 */
public with sharing class ProductUpgradeController {

    private static final String CODE_BATTERY = 'VBOT_BAT_PLUS';
    private static final String CODE_COMFORT_PLUS = 'VBOT_C500';
    private static final String CODE_PRO = 'VBOT_X800';

    @AuraEnabled(cacheable=true)
    public static UpgradeStudioDataDTO getUpgradeData(Id workOrderId) {
        if (workOrderId == null) {
            throw new AuraHandledException('WorkOrder id is required.');
        }

        List<WorkOrder> wos = [
            SELECT Id, AccountId, AssetId,
                   Account.Name,
                   Contact.Name,
                   Asset.Id, Asset.Name, Asset.InstallDate,
                   Asset.VBOT_Property_Size_Sqm__c,
                   Asset.VBOT_Battery_Health_Pct__c,
                   Asset.VBOT_Firmware_Version__c,
                   Asset.Product2Id,
                   Asset.Product2.Name,
                   Asset.Product2.ProductCode,
                   Asset.Product2.VBOT_Hero_Image_Url__c,
                   Asset.Product2.VBOT_Max_Area_Sqm__c,
                   Asset.Product2.VBOT_Battery_Capacity_Wh__c,
                   Asset.Product2.VBOT_Has_GPS__c,
                   Asset.Product2.VBOT_Has_Lawn_AI__c
            FROM WorkOrder
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        if (wos.isEmpty()) {
            throw new AuraHandledException('WorkOrder not found.');
        }
        WorkOrder wo = wos[0];
        if (wo.AssetId == null || wo.Asset.Product2Id == null) {
            throw new AuraHandledException('WorkOrder must reference an Asset with a Product2.');
        }

        Product2 currentProduct = wo.Asset.Product2;
        UpgradeStudioDataDTO dto = new UpgradeStudioDataDTO();
        dto.accountName = wo.Account != null ? wo.Account.Name : '';
        dto.contactName = wo.Contact != null ? wo.Contact.Name : '';
        dto.asset = buildAssetContext(wo.Asset, currentProduct);
        dto.currentProduct = buildCurrentProduct(currentProduct);

        Map<String, Product2> candidates = new Map<String, Product2>();
        for (Product2 p : [
            SELECT Id, Name, ProductCode, VBOT_Tier_Label__c,
                   VBOT_Hero_Image_Url__c, VBOT_Max_Area_Sqm__c,
                   VBOT_Battery_Capacity_Wh__c, VBOT_Has_GPS__c, VBOT_Has_Lawn_AI__c
            FROM Product2
            WHERE ProductCode IN (:CODE_BATTERY, :CODE_COMFORT_PLUS, :CODE_PRO)
        ]) {
            candidates.put(p.ProductCode, p);
        }

        Map<Id, Decimal> priceByProductId = new Map<Id, Decimal>();
        Set<Id> candidateIds = new Set<Id>();
        for (Product2 p : candidates.values()) candidateIds.add(p.Id);
        for (PricebookEntry pbe : [
            SELECT Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = true AND Product2Id IN :candidateIds
        ]) {
            priceByProductId.put(pbe.Product2Id, pbe.UnitPrice);
        }

        dto.options = new List<ProductUpgradeOptionDTO>();
        if (candidates.containsKey(CODE_BATTERY)) {
            dto.options.add(toOption(candidates.get(CODE_BATTERY), priceByProductId,
                'Accessory', 64, false, currentProduct,
                new List<String>{
                    'Schnell montierbar im Service-Termin',
                    'Verdoppelt die Laufzeit pro Ladung',
                    'Spart Folgeeinsatz innerhalb der nächsten 6 Monate'
                },
                'Zu Quote hinzufügen'));
        }
        if (candidates.containsKey(CODE_COMFORT_PLUS)) {
            dto.options.add(toOption(candidates.get(CODE_COMFORT_PLUS), priceByProductId,
                'Comfort+', 86, true, currentProduct,
                new List<String>{
                    'Mäht 1.500 m² – genug für das gewachsene Grundstück',
                    'Größerer Akku entlastet die Service-Pipeline',
                    'Anschaffung amortisiert sich in unter 3 Jahren'
                },
                'Zu Quote hinzufügen'));
        }
        if (candidates.containsKey(CODE_PRO)) {
            dto.options.add(toOption(candidates.get(CODE_PRO), priceByProductId,
                'Pro', 71, false, currentProduct,
                new List<String>{
                    'GPS + Lawn-AI für komplexe Grundstücke',
                    'Beste Wahl bei wachsender Asset-Flotte',
                    'Inkludiert 24M Hardware-Garantie'
                },
                'Zu Quote hinzufügen'));
        }

        dto.reasoning = buildReasoning(wo.Asset, currentProduct);
        return dto;
    }

    private static AssetContextDTO buildAssetContext(Asset a, Product2 p) {
        AssetContextDTO ac = new AssetContextDTO();
        ac.name = a.Name;
        ac.productName = p != null ? p.Name : '';
        ac.productImageUrl = p != null ? p.VBOT_Hero_Image_Url__c : null;
        ac.installedMonthsAgo = monthsBetween(a.InstallDate, Date.today());
        ac.propertySize = a.VBOT_Property_Size_Sqm__c != null
            ? Integer.valueOf(a.VBOT_Property_Size_Sqm__c) : null;
        ac.batteryHealthPct = a.VBOT_Battery_Health_Pct__c;
        ac.firmwareVersion = a.VBOT_Firmware_Version__c;
        return ac;
    }

    private static ProductContextDTO buildCurrentProduct(Product2 p) {
        ProductContextDTO cp = new ProductContextDTO();
        cp.name = p.Name;
        cp.heroImageUrl = p.VBOT_Hero_Image_Url__c;
        cp.specs = new List<SpecRowDTO>{
            specRow('Max. Mähleistung', formatArea(p.VBOT_Max_Area_Sqm__c)),
            specRow('Akku-Kapazität', formatWh(p.VBOT_Battery_Capacity_Wh__c)),
            specRow('GPS-Navigation', boolText(p.VBOT_Has_GPS__c)),
            specRow('Lawn-AI Software', boolText(p.VBOT_Has_Lawn_AI__c))
        };
        return cp;
    }

    private static ProductUpgradeOptionDTO toOption(
        Product2 p, Map<Id, Decimal> priceByProductId,
        String tier, Integer fitScore, Boolean isRecommended,
        Product2 current, List<String> valueProps, String cta
    ) {
        ProductUpgradeOptionDTO o = new ProductUpgradeOptionDTO();
        o.productId = p.Id;
        o.productCode = p.ProductCode;
        o.name = p.Name;
        o.tier = tier;
        o.heroImageUrl = p.VBOT_Hero_Image_Url__c;
        o.price = priceByProductId.get(p.Id);
        o.fitScore = fitScore;
        o.isRecommended = isRecommended;
        o.specs = buildOptionSpecs(p, current);
        o.valueProps = valueProps;
        o.ctaLabel = cta;
        return o;
    }

    private static List<SpecRowDTO> buildOptionSpecs(Product2 candidate, Product2 current) {
        List<SpecRowDTO> rows = new List<SpecRowDTO>();
        rows.add(specRowDiff('Max. Mähleistung',
            formatArea(candidate.VBOT_Max_Area_Sqm__c),
            diffArea(current?.VBOT_Max_Area_Sqm__c, candidate.VBOT_Max_Area_Sqm__c)));
        rows.add(specRowDiff('Akku-Kapazität',
            formatWh(candidate.VBOT_Battery_Capacity_Wh__c),
            diffNumber(current?.VBOT_Battery_Capacity_Wh__c, candidate.VBOT_Battery_Capacity_Wh__c)));
        rows.add(specRowDiff('GPS-Navigation',
            boolText(candidate.VBOT_Has_GPS__c),
            diffFlag(current?.VBOT_Has_GPS__c, candidate.VBOT_Has_GPS__c)));
        rows.add(specRowDiff('Lawn-AI Software',
            boolText(candidate.VBOT_Has_Lawn_AI__c),
            diffFlag(current?.VBOT_Has_Lawn_AI__c, candidate.VBOT_Has_Lawn_AI__c)));
        return rows;
    }

    private static SpecRowDTO specRow(String label, String value) {
        SpecRowDTO r = new SpecRowDTO();
        r.label = label;
        r.value = value;
        r.diff = 'same';
        return r;
    }

    private static SpecRowDTO specRowDiff(String label, String value, String diff) {
        SpecRowDTO r = new SpecRowDTO();
        r.label = label;
        r.value = value;
        r.diff = diff;
        return r;
    }

    private static String diffArea(Decimal currentVal, Decimal candidateVal) {
        if (currentVal == null || candidateVal == null) return 'same';
        if (candidateVal > currentVal) return 'up';
        if (candidateVal < currentVal) return 'down';
        return 'same';
    }

    private static String diffNumber(Decimal currentVal, Decimal candidateVal) {
        if (currentVal == null || candidateVal == null) return 'same';
        if (candidateVal > currentVal) return 'up';
        if (candidateVal < currentVal) return 'down';
        return 'same';
    }

    private static String diffFlag(Boolean currentVal, Boolean candidateVal) {
        Boolean cur = currentVal == true;
        Boolean cand = candidateVal == true;
        if (cand && !cur) return 'up';
        if (!cand && cur) return 'down';
        return 'same';
    }

    private static ReasoningDTO buildReasoning(Asset a, Product2 currentProduct) {
        ReasoningDTO r = new ReasoningDTO();
        r.headline = 'Warum diese Empfehlungen?';
        r.confidence = 86;
        r.bullets = new List<ReasoningBulletDTO>();

        if (a.VBOT_Property_Size_Sqm__c != null && currentProduct?.VBOT_Max_Area_Sqm__c != null) {
            Decimal delta = a.VBOT_Property_Size_Sqm__c - currentProduct.VBOT_Max_Area_Sqm__c;
            if (delta > 0) {
                r.bullets.add(bullet('utility:trending_up',
                    'Grundstück ' + delta.setScale(0) + ' m² über aktueller Mähkapazität.'));
            }
        } else {
            r.bullets.add(bullet('utility:info',
                'Grundstücksgröße unbekannt – Empfehlung basiert nur auf Asset-Alter.'));
        }

        if (a.VBOT_Battery_Health_Pct__c != null) {
            Decimal wear = (100 - a.VBOT_Battery_Health_Pct__c).setScale(0);
            r.bullets.add(bullet('utility:battery_high',
                'Akkuverschleiß bei ' + wear + ' %.'));
        }

        Integer months = monthsBetween(a.InstallDate, Date.today());
        r.bullets.add(bullet('utility:asset_relationship',
            'Asset installiert vor ' + months + ' Monaten.'));

        r.bullets.add(bullet('utility:einstein',
            'Vergleichbare Kunden upgraden im Schnitt nach 14 Monaten.'));

        return r;
    }

    private static ReasoningBulletDTO bullet(String icon, String text) {
        ReasoningBulletDTO b = new ReasoningBulletDTO();
        b.icon = icon;
        b.text = text;
        return b;
    }

    private static String formatArea(Decimal d) {
        return d == null ? '—' : d.setScale(0) + ' m²';
    }

    private static String formatWh(Decimal d) {
        return d == null ? '—' : d.setScale(0) + ' Wh';
    }

    private static String boolText(Boolean b) {
        return b == true ? 'Ja' : 'Nein';
    }

    private static Integer monthsBetween(Date fromDate, Date toDate) {
        if (fromDate == null || toDate == null) return 0;
        Integer months = (toDate.year() - fromDate.year()) * 12 + (toDate.month() - fromDate.month());
        if (toDate.day() < fromDate.day()) months -= 1;
        return Math.max(months, 0);
    }

    public class UpgradeStudioDataDTO {
        @AuraEnabled public AssetContextDTO asset;
        @AuraEnabled public ProductContextDTO currentProduct;
        @AuraEnabled public List<ProductUpgradeOptionDTO> options;
        @AuraEnabled public ReasoningDTO reasoning;
        @AuraEnabled public String accountName;
        @AuraEnabled public String contactName;
    }

    public class AssetContextDTO {
        @AuraEnabled public String name;
        @AuraEnabled public String productName;
        @AuraEnabled public String productImageUrl;
        @AuraEnabled public Integer installedMonthsAgo;
        @AuraEnabled public Integer propertySize;
        @AuraEnabled public Decimal batteryHealthPct;
        @AuraEnabled public String firmwareVersion;
    }

    public class ProductContextDTO {
        @AuraEnabled public String name;
        @AuraEnabled public String heroImageUrl;
        @AuraEnabled public List<SpecRowDTO> specs;
        @AuraEnabled public Decimal price;
    }

    public class ProductUpgradeOptionDTO {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productCode;
        @AuraEnabled public String name;
        @AuraEnabled public String tier;
        @AuraEnabled public String heroImageUrl;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Integer fitScore;
        @AuraEnabled public Boolean isRecommended;
        @AuraEnabled public List<SpecRowDTO> specs;
        @AuraEnabled public List<String> valueProps;
        @AuraEnabled public String ctaLabel;
    }

    public class SpecRowDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String diff;
    }

    public class ReasoningDTO {
        @AuraEnabled public String headline;
        @AuraEnabled public List<ReasoningBulletDTO> bullets;
        @AuraEnabled public Integer confidence;
    }

    public class ReasoningBulletDTO {
        @AuraEnabled public String icon;
        @AuraEnabled public String text;
    }
}
