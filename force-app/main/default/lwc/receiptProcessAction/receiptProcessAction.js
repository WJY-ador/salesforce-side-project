import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import checkDuplicateFiles from '@salesforce/apex/ReceiptExtractorService.checkDuplicateFiles';
import processExpense from '@salesforce/apex/ReceiptExtractorService.processExpense';

export default class ReceiptProcessAction extends NavigationMixin(LightningElement) {
    @api recordId;
    isRunning = false;
    showDuplicateConfirm = false;
    duplicateFiles = [];

    async startProcessing() {
        if (!this.recordId) {
            this.showToast('실패', '레코드 ID를 찾을 수 없습니다.', 'error');
            this.closeAction();
            return;
        }

        try {
            const duplicates = await checkDuplicateFiles({ expenseId: this.recordId });

            if (duplicates && duplicates.length > 0) {
                this.duplicateFiles = duplicates;
                this.showDuplicateConfirm = true;
                return;
            }
        } catch (error) {
            this.showToast('실패', this.getErrorMessage(error), 'error');
            this.closeAction();
            return;
        }

        await this.runProcessing();
    }

    async runProcessing() {
        this.showDuplicateConfirm = false;
        this.isRunning = true;

        try {
            await processExpense({ expenseId: this.recordId });
            this.showToast('완료', '영수증 처리가 완료되었습니다.', 'success');
        } catch (error) {
            this.showToast('실패', this.getErrorMessage(error), 'error');
        } finally {
            this.isRunning = false;
            this.closeAction();
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        return '처리 중 오류가 발생했습니다.';
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}
