import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const PRODUCT_IDS = {
    CN3000: '01tIg000001zgnjIAA',
    XN_SERIES: '01tIg000001zgoTIAQ',
    XR6000: '01tIg000001zgnmIAA'
};

export default class InstrumentProductCards extends NavigationMixin(LightningElement) {
    get products() {
        return [
            {
                key: 'xn',
                name: 'XN-Series™ 소형 자동화 시스템',
                subtitle: 'CBC/DIFF 검사 환경에 적합한 소형 자동화 솔루션',
                description:
                    '중소형 검사실에 적합한 혈액검사 자동화 장비로, 안정적인 처리와 효율적인 워크플로우를 지원합니다.',
                iconName: 'standard:product',
                productId: PRODUCT_IDS.XN_SERIES
            },
            {
                key: 'xr',
                name: 'XR-6000 혈액검사 트랙 시스템',
                subtitle: '고처리량 환경을 위한 혈액검사 트랙 시스템',
                description:
                    '검체 이송과 장비 연결을 통합하여 검사실 전체 처리 효율을 높일 수 있는 트랙 기반 솔루션입니다.',
                iconName: 'standard:product',
                productId: PRODUCT_IDS.XR6000
            },
            {
                key: 'cn',
                name: 'CN-3000™ 자동 혈액응고 분석기',
                subtitle: '응고검사 자동화를 위한 핵심 분석 장비',
                description:
                    '응고검사 프로세스를 자동화하고 시약/소모품 재구매 흐름과 자연스럽게 연결할 수 있는 대표 장비입니다.',
                iconName: 'standard:product',
                productId: PRODUCT_IDS.CN3000
            }
        ];
    }

    handleNavigate(event) {
        const selectedKey = event.currentTarget.dataset.key;
        const selectedProduct = this.products.find((product) => product.key === selectedKey);

        if (!selectedProduct || !selectedProduct.productId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Product Id가 없습니다',
                    message: '선택한 제품의 Product Id를 확인해주세요.',
                    variant: 'warning'
                })
            );
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: selectedProduct.productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleNavigate(event);
        }
    }
}