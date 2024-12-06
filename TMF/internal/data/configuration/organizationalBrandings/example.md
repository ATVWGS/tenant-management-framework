# Example for default organizational branding
# Attention: Default branding cannot be deleted!! Image files cannot be tested against desired state configuration, so they are excluded from TMF.
```json
{
    "present": true,
    "displayName": "default",
    "backgroundColor": "#ffffff",
    "customAccountResetCredentialsUrl": "Your custom URL",
    "customCannotAccessYourAccountText": "Your custom text",
    "customCannotAccessYourAccountUrl": "Your custom URL",
    "customForgotMyPasswordText": "Your custom text",
    "customPrivacyAndCookiesText": "Your custom text",
    "customPrivacyAndCookiesUrl": "Your custom URL",
    "customResetItNowText": "Your custom text",
    "customTermsOfUseText": "Your custom text",
    "customTermsOfUseUrl": "Your custom URL",
    "headerBackgroundColor": "#000000",
    "signInPageText": "Your custom text",
    "usernameHintText": "Your custom text"
}
```
# Example for localized organizational branding
# Hint: Only backgroundColor, signInPageText and usernameHintText are supported to update through Graph API. This causes the reduced attribute set in comparison to default
```json
{
    "present": true,
    "displayName": "en-US",
    "backgroundColor": "#ffffff",
    "signInPageText": "Another custom sign in text",
    "usernameHintText": "Another custom username hint text"
}
```