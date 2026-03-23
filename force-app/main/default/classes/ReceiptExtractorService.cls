public with sharing class ReceiptExtractorService {
    @AuraEnabled
    public static String enqueueExpenseProcessing(Id expenseId) {
        Id jobId = System.enqueueJob(new ReceiptExtractorQueueable(expenseId));
        return (String) jobId;
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
    }

    public class RequestDTO {
        public String image_base64;
        public String mime_type;
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

        Decimal totalAmountSum = 0;
        List<String> summaryBlocks = new List<String>();
        List<ReceiptResponseDTO> rawResults = new List<ReceiptResponseDTO>();

        Http http = new Http();

        for (ContentVersion cv : versions) {
            if (!isSupportedImage(cv.FileExtension)) {
                continue;
            }

            String mimeType = getMimeType(cv.FileExtension);
            String imageBase64 = EncodingUtil.base64Encode(cv.VersionData);

            RequestDTO reqBody = new RequestDTO();
            reqBody.image_base64 = imageBase64;
            reqBody.mime_type = mimeType;

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://receipt-extractor-388173831980.us-central1.run.app/extract-receipt');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            req.setBody(JSON.serialize(reqBody));

            HttpResponse res = http.send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                throw new AuraHandledException(
                    'API 호출 실패 (' + cv.Title + '): ' + res.getStatusCode() + ' / ' + res.getBody()
                );
            }

            ReceiptResponseDTO result =
                (ReceiptResponseDTO) JSON.deserialize(res.getBody(), ReceiptResponseDTO.class);

            rawResults.add(result);

            if (result.total_amount != null) {
                totalAmountSum += result.total_amount;
            }

            summaryBlocks.add(buildSummaryBlock(cv.Title, result));
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

        if (rawResults != null && !rawResults.isEmpty()) {
            ReceiptResponseDTO firstResult = rawResults[0];

            if (firstResult != null) {
                upd.StoreName__c = firstResult.store_name;

                if (firstResult.transaction_date != null) {
                    try {
                        upd.TransactionDate__c = Datetime.valueOf(firstResult.transaction_date);
                    } catch (Exception e) {
                    }
                }
            }
        }

        update upd;
    }

    private static String buildSummaryBlock(String fileTitle, ReceiptResponseDTO result) {
        List<String> lines = new List<String>();

        String header = '[' + (result != null && result.store_name != null ? result.store_name : fileTitle) + ']';
        lines.add(header);

        if (result == null) {
            lines.add('인식 실패');
            return String.join(lines, '\n');
        }

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

        String e = ext.toLowerCase();
        return e == 'png' || e == 'jpg' || e == 'jpeg' || e == 'webp';
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
