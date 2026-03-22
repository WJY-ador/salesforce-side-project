import { LightningElement, api } from 'lwc';

export default class AccountSummaryMock extends LightningElement {
    @api cardTitle = '계정 요약 (Account Summary)';
    @api industryGroup = '상급종합병원';
    @api companySize = '1,000병상 이상';
    @api statusLabel = 'Active';

    tagList = [
        { id: '1', label: '진단검사의학과', className: 'summary-badge summary-badge_brand' },
        { id: '2', label: '전사 사용중', className: 'summary-badge summary-badge_neutral' },
        { id: '3', label: '재계약 3개월 전', className: 'summary-badge summary-badge_error' },
        { id: '4', label: '주력 고객', className: 'summary-badge summary-badge_success' }
    ];

    linkList = [
        {
            id: '1',
            label: '구글 드라이브 (공유 문서)',
            iconName: 'utility:link',
            url: 'https://drive.google.com'
        },
        {
            id: '2',
            label: '내부 문서',
            iconName: 'utility:link',
            url: 'https://example.com/internal-doc'
        },
        {
            id: '3',
            label: '고객사 웹사이트',
            iconName: 'utility:world',
            url: 'https://www.cmcseoul.or.kr'
        }
    ];
}