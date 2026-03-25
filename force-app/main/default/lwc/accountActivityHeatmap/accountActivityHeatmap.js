import { LightningElement, api, wire, track } from 'lwc';
import getAccountActivities from '@salesforce/apex/AccountActivityHeatmapController.getAccountActivities';

const DAYS_BACK = 90;
const DOW_LABELS = [
    { id: 'd0', text: 'Sun' },
    { id: 'd1', text: 'Mon' },
    { id: 'd2', text: 'Tue' },
    { id: 'd3', text: 'Wed' },
    { id: 'd4', text: 'Thu' },
    { id: 'd5', text: 'Fri' },
    { id: 'd6', text: 'Sat' }
];

export default class AccountActivityHeatmap extends LightningElement {
    @api recordId;
    @api daysBack = 90;

    @track filter = 'All';
    @track selectedDay = null;

    _rawActivities = [];
    loading = true;
    error = null;

    @wire(getAccountActivities, { accountId: '$recordId', daysBack: '$daysBack' })
    wiredActivities({ data, error }) {
        this.loading = false;
        if (data) {
            this._rawActivities = data;
        } else if (error) {
            this.error = error.body?.message ?? '데이터를 불러올 수 없습니다.';
        }
    }

    get dayLabels() { return DOW_LABELS; }

    get filterButtons() {
        return ['All', 'Task', 'Event'].map(f => ({
            value: f,
            label: f,
            cssClass: `filter-btn${this.filter === f ? ' filter-btn--active' : ''}`
        }));
    }

    // ── Computed ──────────────────────────────────────────────────
    get _actMap() {
        const map = {};
        let idx = 0;
        for (const a of this._rawActivities) {
            if (this.filter !== 'All' && a.type !== this.filter) continue;
            if (!map[a.activityDate]) map[a.activityDate] = [];
            
            const badgeLabel = a.subtype ? a.subtype : a.type;
            const badgeClassSafe = badgeLabel.replace(/[\s/]/g, '').toLowerCase();

            map[a.activityDate].push({
                _id:          String(idx++),
                subject:      a.subject,
                type:         a.type,
                subtype:      a.subtype,
                status:       a.status,
                priority:     a.priority,
                badgeLabel:   badgeLabel,
                typeBadgeClass: `act-badge act-badge--${badgeClassSafe}`
            });
        }
        return map;
    }

    get weeks() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayKey = this._dateKey(today);

        const start = new Date(today);
        start.setDate(start.getDate() - (this.daysBack - 1));

        const actMap = this._actMap;

        // Build flat cell array with leading blanks for DOW alignment
        const cells = [];
        const startDow = start.getDay(); // 0=Sun

        for (let i = 0; i < startDow; i++) {
            cells.push({ key: `bs${i}`, blank: true, cellClass: 'day-cell day-blank' });
        }

        for (let i = 0; i < this.daysBack; i++) {
            const d = new Date(start);
            d.setDate(d.getDate() + i);
            const key   = this._dateKey(d);
            const count = (actMap[key] || []).length;
            const isToday = key === todayKey;

            cells.push({
                key,
                blank:     false,
                count,
                isToday,
                cellClass: `day-cell level-${this._level(count)}${isToday ? ' is-today' : ''}`,
                label:     `${key}${isToday ? ' (오늘)' : ''} : ${count > 0 ? count + '개 활동' : '활동 없음'}`
            });
        }

        // Pad trailing blanks to complete last week
        while (cells.length % 7 !== 0) {
            cells.push({ key: `be${cells.length}`, blank: true, cellClass: 'day-cell day-blank' });
        }

        // Slice into week columns of 7 rows, add month label when month changes
        const weeks = [];
        const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        let lastMonth = -1;
        for (let i = 0; i < cells.length; i += 7) {
            const weekDays = cells.slice(i, i + 7);
            const firstReal = weekDays.find(d => !d.blank);
            let monthLabel = '';
            if (firstReal) {
                const mo = parseInt(firstReal.key.split('-')[1], 10) - 1;
                if (mo !== lastMonth) { monthLabel = MONTHS[mo]; lastMonth = mo; }
            }
            weeks.push({ id: `w${i / 7}`, days: weekDays, monthLabel });
        }
        return weeks;
    }

    get hasSelectedDay()       { return !!this.selectedDay; }
    get popoverTitle() {
        if (!this.selectedDay) return '';
        const [y, m, d] = this.selectedDay.date.split('-');
        const dow = ['일', '월', '화', '수', '목', '금', '토'][new Date(+y, +m - 1, +d).getDay()];
        return `${+m}월 ${+d}일 (${dow})`;
    }
    get popoverActivities()    { return this.selectedDay?.activities ?? []; }
    get hasPopoverActivities() { return this.popoverActivities.length > 0; }
    get isEmpty()              { return !this.loading && !this.error && this._rawActivities.length === 0; }

    // ── Helpers ───────────────────────────────────────────────────
    _level(count) {
        if (count === 0) return 0;
        if (count === 1) return 1;
        if (count <= 3) return 2;
        if (count <= 6) return 3;
        return 4;
    }

    _dateKey(d) {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    }

    // ── Handlers ──────────────────────────────────────────────────
    handleFilter(event) {
        this.filter = event.currentTarget.dataset.value;
        this.selectedDay = null;
    }

    handleDayClick(event) {
        const key = event.currentTarget.dataset.key;
        if (!key || !/^\d{4}-/.test(key)) return; // ignore blank cells
        if (this.selectedDay?.date === key) {
            this.selectedDay = null;
        } else {
            this.selectedDay = { date: key, activities: this._actMap[key] ?? [] };
        }
    }

    handleClosePopover() {
        this.selectedDay = null;
    }
}
