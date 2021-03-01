# Notes
This file contains some general information, that may be relevant while developing TMF.

# Components
Currently I have just added some mandatory components. I'm also using displayName as uniqe property. So when loading components from all configurations, I am removing component duplicates by the display name. (see *functions\general\Load-TmfConfiguration.ps1.*)
Be careful! The displayName is no unique on the Azure AD / Microsoft Graph side.

