public with sharing class ReceiptExtractorService {
    @AuraEnabled
    public static List<String> checkDuplicateFiles(Id expenseId) {
        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :expenseId
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdls) {
            docIds.add(cdl.ContentDocumentId);
        }

        List<ContentVersion> versions = [
            SELECT Title
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
              AND IsLatest = true
        ];

        Map<String, Integer> titleCount = new Map<String, Integer>();
        for (ContentVersion cv : versions) {
            Integer cnt = titleCount.containsKey(cv.Title) ? titleCount.get(cv.Title) : 0;
            titleCount.put(cv.Title, cnt + 1);
        }

        List<String> duplicates = new List<String>();
        for (String title : titleCount.keySet()) {
            if (titleCount.get(title) > 1) {
                duplicates.add(title);
            }
        }

        return duplicates;
    }

    public class ReceiptItemDTO {
        public String name;
        public Decimal quantity;
        public Decimal price;
    }

    public class ReceiptResponseDTO {
        public String store_name;
        public String transaction_date;
        public Decimal total_amount;
        public List<ReceiptItemDTO> items;
        public String category;
        public String summary;
        public Boolean is_anomaly;
        public String anomaly_reason;
    }

    private static final String BATCH_ENDPOINT =
        'https://receipt-extractor-388173831980.us-central1.run.app/extract-receipts-batch';

    private static final Set<String> SUPPORTED_EXTENSIONS = new Set<String>{
        'png', 'jpg', 'jpeg', 'webp'
    };

    private static final List<String> VALID_CATEGORIES = new List<String>{
        '식비', '교통비', '숙박비', '회의비', '접대비', '소모품비', '기타'
    };

    private static String mapCategory(String aiCategory) {
        if (aiCategory == null) return '기타';
        for (String valid : VALID_CATEGORIES) {
            if (aiCategory.contains(valid)) return valid;
        }
        return '기타';
    }

    public class RequestDTO {
        public String image_base64;
        public String mime_type;
    }

    public class BatchRequestDTO {
        public List<RequestDTO> receipts;
    }

    @AuraEnabled
    public static String processExpense(Id expenseId) {
        Expense__c expense = [
            SELECT Id, Name
            FROM Expense__c
            WHERE Id = :expenseId
            LIMIT 1
        ];

        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :expense.Id
            ORDER BY SystemModstamp DESC
        ];

        if (cdls.isEmpty()) {
            throw new AuraHandledException('첨부된 파일이 없습니다.');
        }

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdls) {
            docIds.add(cdl.ContentDocumentId);
        }

        List<ContentVersion> versions = [
            SELECT Id, Title, FileExtension, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
              AND IsLatest = true
            ORDER BY Title
        ];

        if (versions.isEmpty()) {
            throw new AuraHandledException('처리할 최신 파일이 없습니다.');
        }

        // 지원 이미지만 필터링하여 배치 요청 구성
        List<RequestDTO> requestList = new List<RequestDTO>();
        List<ContentVersion> filteredVersions = new List<ContentVersion>();

        for (ContentVersion cv : versions) {
            if (!isSupportedImage(cv.FileExtension)) {
                continue;
            }
            RequestDTO r = new RequestDTO();
            r.image_base64 = EncodingUtil.base64Encode(cv.VersionData);
            r.mime_type = getMimeType(cv.FileExtension);
            requestList.add(r);
            filteredVersions.add(cv);
        }

        if (requestList.isEmpty()) {
            throw new AuraHandledException('지원되는 이미지 파일이 없습니다. (png, jpg, jpeg, webp)');
        }

        // 배치 엔드포인트에 한 번에 전송
        BatchRequestDTO batchBody = new BatchRequestDTO();
        batchBody.receipts = requestList;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(BATCH_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(batchBody));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException(
                '배치 API 호출 실패: ' + res.getStatusCode() + ' / ' + res.getBody()
            );
        }

        List<ReceiptResponseDTO> rawResults =
            (List<ReceiptResponseDTO>) JSON.deserialize(res.getBody(), List<ReceiptResponseDTO>.class);

        Decimal totalAmountSum = 0;
        List<String> summaryBlocks = new List<String>();

        if (rawResults.size() != filteredVersions.size()) {
            throw new AuraHandledException(
                '응답 수(' + rawResults.size() + ')와 요청 파일 수(' + filteredVersions.size() + ')가 일치하지 않습니다.'
            );
        }

        for (Integer i = 0; i < rawResults.size(); i++) {
            ReceiptResponseDTO result = rawResults[i];
            String fileTitle = filteredVersions[i].Title;

            if (result.total_amount != null) {
                totalAmountSum += result.total_amount;
            }
            summaryBlocks.add(buildSummaryBlock(fileTitle, result));
        }

        updateExpense(expense.Id, totalAmountSum, summaryBlocks, rawResults);

        return JSON.serialize(rawResults);
    }

    private static void updateExpense(
        Id expenseId,
        Decimal totalAmountSum,
        List<String> summaryBlocks,
        List<ReceiptResponseDTO> rawResults
    ) {
        Expense__c upd = new Expense__c(
            Id = expenseId,
            TotalAmount__c = totalAmountSum,
            AIProcessed__c = true,
            RawJSON__c = JSON.serialize(rawResults),
            ItemsSummary__c = String.join(summaryBlocks, '\n\n')
        );

        if (!rawResults.isEmpty()) {
            ReceiptResponseDTO firstResult = rawResults[0];

            upd.StoreName__c = firstResult.store_name;

            if (firstResult.transaction_date != null) {
                try {
                    upd.TransactionDate__c = Datetime.valueOf(firstResult.transaction_date);
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, '날짜 파싱 실패: ' + firstResult.transaction_date + ' / ' + e.getMessage());
                }
            }

            // Category: 첫 번째 결과 기준 (Picklist 매핑)
            upd.Category__c = mapCategory(firstResult.category);

            // Summary: 여러 영수증이면 합쳐서, 하나면 그대로
            List<String> summaries = new List<String>();
            Boolean anyAnomaly = false;
            List<String> anomalyReasons = new List<String>();

            for (ReceiptResponseDTO r : rawResults) {
                if (r.summary != null) summaries.add(r.summary);
                if (r.is_anomaly == true) {
                    anyAnomaly = true;
                    if (r.anomaly_reason != null) anomalyReasons.add(r.anomaly_reason);
                }
            }

            if (!summaries.isEmpty()) {
                upd.Summary__c = String.join(summaries, ' / ');
            }
            upd.IsAnomaly__c = anyAnomaly;
            if (!anomalyReasons.isEmpty()) {
                upd.AnomalyReason__c = String.join(anomalyReasons, ' | ');
            }
        }

        update upd;
    }

    private static String buildSummaryBlock(String fileTitle, ReceiptResponseDTO result) {
        List<String> lines = new List<String>();

        if (result == null) {
            lines.add('[' + fileTitle + ']');
            lines.add('인식 실패');
            return String.join(lines, '\n');
        }

        String header = '[' + (result.store_name != null ? result.store_name : fileTitle) + ']';
        lines.add(header);

        if (result.transaction_date != null) {
            lines.add('일시: ' + result.transaction_date);
        }

        if (result.total_amount != null) {
            lines.add('총액: ' + String.valueOf(result.total_amount));
        }

        if (result.items == null || result.items.isEmpty()) {
            lines.add('품목 없음');
            return String.join(lines, '\n');
        }

        for (ReceiptItemDTO item : result.items) {
            String line = '';
            line += (item.name != null ? item.name : '항목없음');

            if (item.quantity != null) {
                line += ' x ' + String.valueOf(item.quantity);
            }

            if (item.price != null) {
                line += ' / ' + String.valueOf(item.price);
            }

            lines.add(line);
        }

        return String.join(lines, '\n');
    }

    private static Boolean isSupportedImage(String ext) {
        if (ext == null) return false;
        return SUPPORTED_EXTENSIONS.contains(ext.toLowerCase());
    }

    private static String getMimeType(String ext) {
        if (ext == null) return 'image/jpeg';

        String e = ext.toLowerCase();
        if (e == 'png') return 'image/png';
        if (e == 'jpg' || e == 'jpeg') return 'image/jpeg';
        if (e == 'webp') return 'image/webp';

        return 'image/jpeg';
    }
}
