import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import login from '@salesforce/apex/CustomLoginController.login';
import basePath from '@salesforce/community/basePath';

export default class CustomLogin extends NavigationMixin(LightningElement) {

    // Public properties (configurable in Experience Builder)
    @api startUrl = '';
    @api logoUrl = '';
    @api brandColor = '#0176d3';

    // Form state
    @track username = '';
    @track password = '';
    @track rememberMe = false;
    @track isLoading = false;

    // Error state
    @track errorMessage = '';
    @track usernameError = '';
    @track passwordError = '';

    // Password visibility
    @track showPassword = false;

    // ─── Computed Properties ────────────────────────────────────────────────

    get passwordFieldType() {
        return this.showPassword ? 'text' : 'password';
    }

    get passwordToggleIcon() {
        return this.showPassword ? 'utility:hide' : 'utility:preview';
    }

    get togglePasswordLabel() {
        return this.showPassword ? 'Hide password' : 'Show password';
    }

    get usernameClass() {
        return `form-input${this.usernameError ? ' input-error' : ''}`;
    }

    get passwordClass() {
        return `form-input${this.passwordError ? ' input-error' : ''}`;
    }

    get forgotPasswordUrl() {
        return `${basePath}/ForgotPassword`;
    }

    get registerUrl() {
        return `${basePath}/SelfRegister`;
    }

    // ─── Event Handlers ─────────────────────────────────────────────────────

    handleUsernameChange(event) {
        this.username = event.target.value;
        if (this.usernameError) this.usernameError = '';
        if (this.errorMessage) this.errorMessage = '';
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        if (this.passwordError) this.passwordError = '';
        if (this.errorMessage) this.errorMessage = '';
    }

    handleRememberMe(event) {
        this.rememberMe = event.target.checked;
    }

    togglePasswordVisibility() {
        this.showPassword = !this.showPassword;
    }

    handleSubmit(event) {
        event.preventDefault();
        if (!this.validateForm()) return;
        this.doLogin();
    }

    // ─── Validation ─────────────────────────────────────────────────────────

    validateForm() {
        let isValid = true;

        if (!this.username || !this.username.trim()) {
            this.usernameError = 'Username is required.';
            isValid = false;
        }

        if (!this.password || !this.password.trim()) {
            this.passwordError = 'Password is required.';
            isValid = false;
        }

        return isValid;
    }

    // ─── Login Logic ─────────────────────────────────────────────────────────

    doLogin() {
        this.isLoading = true;
        this.errorMessage = '';

        const redirectUrl = this.startUrl || '/';

        login({ username: this.username, password: this.password, startUrl: redirectUrl })
            .then(pageUrl => {
                if (pageUrl) {
                    window.location.href = pageUrl;
                } else {
                    this.errorMessage = 'Invalid username or password. Please try again.';
                }
            })
            .catch(error => {
                const msg = error?.body?.message || error?.message || 'An unexpected error occurred. Please try again.';
                this.errorMessage = msg;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
