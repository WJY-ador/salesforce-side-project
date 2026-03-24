import { LightningElement, track } from 'lwc';
import getApiKey from '@salesforce/apex/KakaoMapController.getApiKey';

export default class KakaoMap extends LightningElement {
    @track searchKeyword = '';
    @track selectedAddress = '';
    map;
    marker;

    connectedCallback() {
        // Apex에서 API Key 가져온 후 Kakao SDK 동적 로드
        getApiKey()
            .then(apiKey => {
                const script = document.createElement('script');
                // autoload=false → 수동으로 kakao.maps.load() 호출 (SDK 로드 타이밍 제어)
                script.src = `https://dapi.kakao.com/v2/maps/sdk.js?appkey=${apiKey}&libraries=services&autoload=false`;
                script.onload = () => {
                    window.kakao.maps.load(() => {
                        this.initMap();
                    });
                };
                document.head.appendChild(script);
            })
            .catch(error => {
                console.error('API Key 로드 실패:', error);
            });
    }

    initMap() {
        // Shadow DOM 때문에 this.template.querySelector 필수 (document.getElementById 사용 불가)
        const container = this.template.querySelector('#map');
        const options = {
            center: new window.kakao.maps.LatLng(37.5665, 126.9780), // 서울 시청 기본값
            level: 3
        };
        this.map = new window.kakao.maps.Map(container, options);
        this.marker = new window.kakao.maps.Marker({
            position: options.center,
            map: this.map
        });
    }

    handleInput(event) {
        this.searchKeyword = event.target.value;
    }

    handleSearch() {
        if (!this.searchKeyword) return;

        const geocoder = new window.kakao.maps.services.Geocoder();
        geocoder.addressSearch(this.searchKeyword, (result, status) => {
            if (status === window.kakao.maps.services.Status.OK) {
                const coords = new window.kakao.maps.LatLng(result[0].y, result[0].x);
                this.marker.setPosition(coords);
                this.map.setCenter(coords);
                this.selectedAddress = result[0].address_name;
            } else {
                alert('주소를 찾을 수 없습니다.');
            }
        });
    }
}
