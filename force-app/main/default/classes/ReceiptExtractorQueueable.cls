public with sharing class ReceiptExtractorQueueable implements Queueable, Database.AllowsCallouts {
    private Id expenseId;

    public ReceiptExtractorQueueable(Id expenseId) {
        this.expenseId = expenseId;
    }

    public void execute(QueueableContext context) {
        if (expenseId == null) {
            return;
        }

        ReceiptExtractorService.processExpense(expenseId);
    }
}
