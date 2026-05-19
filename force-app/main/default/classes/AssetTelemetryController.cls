/**
 * VerdantBot demo Apex controller for the connectedAssetDashboard LWC.
 *
 * Aggregates the seeded VBOT_Asset_Telemetry__c rows into DTOs ready for
 * SVG rendering: KPI snapshot, timeline, lawn zones (deterministic) and a
 * linear-regression-based maintenance forecast.
 */
public with sharing class AssetTelemetryController {

    private static final Integer LIMIT_7D = 7;
    private static final Integer LIMIT_30D = 30;
    private static final Integer LIMIT_90D = 90;

    @AuraEnabled(cacheable=true)
    public static DashboardDataDTO getDashboardData(Id assetId, String range) {
        if (assetId == null) {
            throw new AuraHandledException('Asset id is required.');
        }
        Integer limitDays = resolveLimit(range);

        List<Asset> assets = [
            SELECT Id, Name, AccountId, Account.Name, Product2.Name,
                   VBOT_Property_Size_Sqm__c,
                   VBOT_Battery_Health_Pct__c,
                   VBOT_Firmware_Version__c,
                   VBOT_Last_Sync__c,
                   VBOT_Mobile_App_Enabled__c
            FROM Asset
            WHERE Id = :assetId
            LIMIT 1
        ];
        if (assets.isEmpty()) {
            throw new AuraHandledException('Asset not found.');
        }
        Asset asset = assets[0];

        List<VBOT_Asset_Telemetry__c> rawTel = [
            SELECT Id, VBOT_Timestamp__c, VBOT_Battery_Health_Pct__c,
                   VBOT_Mowed_Area_Sqm__c, VBOT_Operating_Hours__c,
                   VBOT_Error_Count__c, VBOT_Firmware_Version__c,
                   VBOT_Lawn_Health_Score__c
            FROM VBOT_Asset_Telemetry__c
            WHERE VBOT_Asset__c = :assetId
            ORDER BY VBOT_Timestamp__c ASC
            LIMIT :LIMIT_30D
        ];

        DashboardDataDTO dto = new DashboardDataDTO();
        dto.asset = buildAssetMeta(asset);
        dto.syncStatus = buildSyncStatus(asset);
        dto.kpis = buildKpis(asset, rawTel);
        dto.timeline = buildTimeline(rawTel, limitDays);
        dto.lawnZones = buildLawnZones(assetId);
        dto.forecast = buildForecast(asset, rawTel);
        dto.mobileMirror = buildMobileMirror(asset, rawTel, dto.lawnZones);
        return dto;
    }

    private static Integer resolveLimit(String range) {
        if (range == '7d') return LIMIT_7D;
        if (range == '90d') return LIMIT_90D;
        return LIMIT_30D;
    }

    private static AssetMetaDTO buildAssetMeta(Asset a) {
        AssetMetaDTO m = new AssetMetaDTO();
        m.name = a.Name;
        m.productName = a.Product2 != null ? a.Product2.Name : '';
        m.propertySize = a.VBOT_Property_Size_Sqm__c != null
            ? Integer.valueOf(a.VBOT_Property_Size_Sqm__c) : null;
        return m;
    }

    private static SyncStatusDTO buildSyncStatus(Asset a) {
        SyncStatusDTO s = new SyncStatusDTO();
        s.lastMobileSyncMillis = a.VBOT_Last_Sync__c != null
            ? a.VBOT_Last_Sync__c.getTime() : null;
        s.lastPortalSync = 'live';
        s.isLive = a.VBOT_Mobile_App_Enabled__c == true;
        return s;
    }

    private static List<KpiTileDTO> buildKpis(Asset a, List<VBOT_Asset_Telemetry__c> rows) {
        List<KpiTileDTO> kpis = new List<KpiTileDTO>();

        Decimal latestBattery = a.VBOT_Battery_Health_Pct__c;
        Decimal earlierBattery;
        if (!rows.isEmpty()) {
            earlierBattery = rows[0].VBOT_Battery_Health_Pct__c;
            latestBattery = rows[rows.size() - 1].VBOT_Battery_Health_Pct__c != null
                ? rows[rows.size() - 1].VBOT_Battery_Health_Pct__c
                : latestBattery;
        }
        String batteryTrend = 'flat';
        if (latestBattery != null && earlierBattery != null) {
            if (latestBattery < earlierBattery) batteryTrend = 'down';
            else if (latestBattery > earlierBattery) batteryTrend = 'up';
        }
        KpiTileDTO battery = new KpiTileDTO();
        battery.key = 'battery';
        battery.label = 'Akku-Gesundheit';
        battery.value = latestBattery != null ? String.valueOf(latestBattery.setScale(0)) : '—';
        battery.unit = '%';
        battery.trend = batteryTrend;
        battery.donutPercent = latestBattery != null ? Integer.valueOf(latestBattery) : 0;
        kpis.add(battery);

        Decimal opSum = 0;
        Decimal mowSum = 0;
        for (VBOT_Asset_Telemetry__c r : rows) {
            if (r.VBOT_Operating_Hours__c != null) opSum += r.VBOT_Operating_Hours__c;
            if (r.VBOT_Mowed_Area_Sqm__c != null) mowSum += r.VBOT_Mowed_Area_Sqm__c;
        }
        KpiTileDTO opHours = new KpiTileDTO();
        opHours.key = 'opHours';
        opHours.label = 'Betriebsstunden';
        opHours.value = String.valueOf(opSum.setScale(1));
        opHours.unit = 'h';
        opHours.trend = 'up';
        kpis.add(opHours);

        KpiTileDTO mowed = new KpiTileDTO();
        mowed.key = 'mowed';
        mowed.label = 'Gemähte Fläche (30 T)';
        mowed.value = String.valueOf(mowSum.setScale(0));
        mowed.unit = 'm²';
        mowed.trend = 'up';
        kpis.add(mowed);

        KpiTileDTO firmware = new KpiTileDTO();
        firmware.key = 'firmware';
        firmware.label = 'Firmware';
        firmware.value = a.VBOT_Firmware_Version__c != null ? a.VBOT_Firmware_Version__c : '—';
        firmware.unit = '';
        firmware.trend = 'flat';
        kpis.add(firmware);

        return kpis;
    }

    private static List<TimelinePointDTO> buildTimeline(List<VBOT_Asset_Telemetry__c> rows, Integer limitDays) {
        List<TimelinePointDTO> points = new List<TimelinePointDTO>();
        List<VBOT_Asset_Telemetry__c> source = rows;
        if (limitDays == LIMIT_7D && rows.size() > 7) {
            source = new List<VBOT_Asset_Telemetry__c>();
            for (Integer i = rows.size() - 7; i < rows.size(); i++) {
                source.add(rows[i]);
            }
        }
        for (VBOT_Asset_Telemetry__c r : source) {
            TimelinePointDTO p = new TimelinePointDTO();
            p.dateValue = r.VBOT_Timestamp__c != null ? r.VBOT_Timestamp__c.dateGmt() : null;
            p.batteryHealth = r.VBOT_Battery_Health_Pct__c;
            p.mowedArea = r.VBOT_Mowed_Area_Sqm__c != null
                ? Integer.valueOf(r.VBOT_Mowed_Area_Sqm__c) : 0;
            p.errorCount = r.VBOT_Error_Count__c != null
                ? Integer.valueOf(r.VBOT_Error_Count__c) : 0;
            points.add(p);
        }
        if (limitDays == LIMIT_90D && !rows.isEmpty()) {
            points = extrapolateBackwards(points);
        }
        return points;
    }

    private static List<TimelinePointDTO> extrapolateBackwards(List<TimelinePointDTO> base) {
        if (base.size() < 2) return base;
        List<TimelinePointDTO> extended = new List<TimelinePointDTO>();
        TimelinePointDTO first = base[0];
        Decimal seed = first.batteryHealth != null ? first.batteryHealth : 90;
        Date startDate = first.dateValue != null ? first.dateValue : Date.today().addDays(-30);
        for (Integer i = 60; i > 0; i--) {
            TimelinePointDTO p = new TimelinePointDTO();
            p.dateValue = startDate.addDays(-i);
            Decimal drift = (Math.mod(Math.abs(String.valueOf(p.dateValue).hashCode()), 100) / 100.0) * 4 - 2;
            p.batteryHealth = (seed + (i / 60.0) * 8 + drift).setScale(2);
            p.mowedArea = 200 + Math.mod(Math.abs(String.valueOf(p.dateValue).hashCode()), 160);
            p.errorCount = Math.mod(Math.abs(String.valueOf(p.dateValue).hashCode()), 13) == 0 ? 1 : 0;
            extended.add(p);
        }
        extended.addAll(base);
        return extended;
    }

    private static List<LawnZoneDTO> buildLawnZones(Id assetId) {
        List<LawnZoneDTO> zones = new List<LawnZoneDTO>();
        zones.add(zone('A', 20,  20,  140, 80,  85, 'Zone A · Vorne links'));
        zones.add(zone('B', 180, 20,  200, 80,  72, 'Zone B · Vorne rechts'));
        zones.add(zone('C', 20,  120, 170, 100, 58, 'Zone C · Hinten links'));
        zones.add(zone('D', 210, 120, 170, 100, 80, 'Zone D · Hinten rechts'));
        return zones;
    }

    private static LawnZoneDTO zone(String id, Integer x, Integer y, Integer w, Integer h, Integer health, String label) {
        LawnZoneDTO z = new LawnZoneDTO();
        z.id = id;
        z.x = x; z.y = y;
        z.width = w; z.height = h;
        z.healthScore = health;
        z.label = label;
        return z;
    }

    private static MaintenanceForecastDTO buildForecast(Asset a, List<VBOT_Asset_Telemetry__c> rows) {
        MaintenanceForecastDTO f = new MaintenanceForecastDTO();
        f.headline = 'Predictive Maintenance';
        f.confidence = 82;
        f.suggestedAction = 'Akku-Tausch + Sensor-Kalibrierung';
        f.reasoning = new List<String>();

        if (rows.isEmpty() || a.VBOT_Battery_Health_Pct__c == null) {
            f.daysUntil = 0;
            f.predictedDate = Date.today();
            f.reasoning.add('Keine Telemetrie-Daten verfügbar – Forecast nicht berechnet.');
            return f;
        }

        Decimal n = rows.size();
        Decimal sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        for (Integer i = 0; i < rows.size(); i++) {
            Decimal x = i;
            Decimal y = rows[i].VBOT_Battery_Health_Pct__c != null
                ? rows[i].VBOT_Battery_Health_Pct__c : 0;
            sumX += x;
            sumY += y;
            sumXY += x * y;
            sumXX += x * x;
        }
        Decimal denom = (n * sumXX - sumX * sumX);
        Decimal slope = denom == 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
        Decimal intercept = (sumY - slope * sumX) / n;
        Decimal target = 65;
        Integer daysUntil = 60;
        if (slope < 0) {
            Decimal xAtTarget = (target - intercept) / slope;
            daysUntil = Math.max(7, Math.min(180, Integer.valueOf(xAtTarget - (rows.size() - 1))));
        }
        f.daysUntil = daysUntil;
        f.predictedDate = Date.today().addDays(daysUntil);
        Decimal wear = (100 - a.VBOT_Battery_Health_Pct__c).setScale(0);
        Decimal absSlope = (slope < 0 ? -slope : slope);
        f.reasoning.add('Akku-Degradation auf ' + a.VBOT_Battery_Health_Pct__c.setScale(0) + ' % – linearer Trend deutet auf 65 % in ~' + daysUntil + ' Tagen.');
        f.reasoning.add('Verschleißrate ' + absSlope.setScale(2) + ' Prozentpunkte/Tag.');
        f.reasoning.add('Operating-Pattern unverändert · keine Firmware-Updates anstehend.');
        return f;
    }

    private static MobileMirrorDTO buildMobileMirror(
        Asset a, List<VBOT_Asset_Telemetry__c> rows, List<LawnZoneDTO> zones
    ) {
        MobileMirrorDTO m = new MobileMirrorDTO();
        m.batteryHealth = a.VBOT_Battery_Health_Pct__c != null
            ? a.VBOT_Battery_Health_Pct__c : 0;
        m.mowedToday = !rows.isEmpty() && rows[rows.size() - 1].VBOT_Mowed_Area_Sqm__c != null
            ? Integer.valueOf(rows[rows.size() - 1].VBOT_Mowed_Area_Sqm__c) : 0;
        m.nextMow = 'Morgen 06:30';
        m.lawnZones = zones;

        if (a.AccountId != null) {
            List<ServiceContract> active = [
                SELECT Name, EndDate FROM ServiceContract
                WHERE AccountId = :a.AccountId
                  AND VBOT_Is_Template__c = false
                  AND Name LIKE 'VBOT %'
                ORDER BY EndDate ASC
                LIMIT 1
            ];
            if (!active.isEmpty()) {
                m.contractName = active[0].Name;
                m.contractExpiresInDays = active[0].EndDate != null
                    ? Date.today().daysBetween(active[0].EndDate) : null;
            }
        }
        if (m.contractName == null) {
            m.contractName = 'VerdantCare';
            m.contractExpiresInDays = 0;
        }
        return m;
    }

    public class DashboardDataDTO {
        @AuraEnabled public AssetMetaDTO asset;
        @AuraEnabled public SyncStatusDTO syncStatus;
        @AuraEnabled public List<KpiTileDTO> kpis;
        @AuraEnabled public List<TimelinePointDTO> timeline;
        @AuraEnabled public List<LawnZoneDTO> lawnZones;
        @AuraEnabled public MaintenanceForecastDTO forecast;
        @AuraEnabled public MobileMirrorDTO mobileMirror;
    }

    public class AssetMetaDTO {
        @AuraEnabled public String name;
        @AuraEnabled public String productName;
        @AuraEnabled public Integer propertySize;
    }

    public class SyncStatusDTO {
        @AuraEnabled public Long lastMobileSyncMillis;
        @AuraEnabled public String lastPortalSync;
        @AuraEnabled public Boolean isLive;
    }

    public class KpiTileDTO {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String unit;
        @AuraEnabled public String trend;
        @AuraEnabled public Integer donutPercent;
    }

    public class TimelinePointDTO {
        @AuraEnabled public Date dateValue;
        @AuraEnabled public Decimal batteryHealth;
        @AuraEnabled public Integer mowedArea;
        @AuraEnabled public Integer errorCount;
    }

    public class LawnZoneDTO {
        @AuraEnabled public String id;
        @AuraEnabled public Integer x;
        @AuraEnabled public Integer y;
        @AuraEnabled public Integer width;
        @AuraEnabled public Integer height;
        @AuraEnabled public Integer healthScore;
        @AuraEnabled public String label;
    }

    public class MaintenanceForecastDTO {
        @AuraEnabled public String headline;
        @AuraEnabled public Date predictedDate;
        @AuraEnabled public Integer daysUntil;
        @AuraEnabled public List<String> reasoning;
        @AuraEnabled public Integer confidence;
        @AuraEnabled public String suggestedAction;
    }

    public class MobileMirrorDTO {
        @AuraEnabled public Decimal batteryHealth;
        @AuraEnabled public Integer mowedToday;
        @AuraEnabled public String nextMow;
        @AuraEnabled public String contractName;
        @AuraEnabled public Integer contractExpiresInDays;
        @AuraEnabled public List<LawnZoneDTO> lawnZones;
    }
}
