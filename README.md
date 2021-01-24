# Microsoft Azure Conditional Access Validator

Conditional Access policies, at their simplest, are if-then statements. If a user wants to access a resource, they must complete an action. Conditional Access contains many settings, and they can complement each other. Misconfiguration can take place when having multiple Conditional Access policies. I created a PowerShell script for companies to validate their Conditional Access configuration.

For more information about my Microsoft Azure Conditional Access Validator, please check my blog post:  
https://thalpius.com/2021/01/25/microsoft-azure-conditional-access-validator/

# Usage

```PowerShell
Import-Module Invoke-AzureCAValidator.psm1

CheckLegacyAuth -Username user@thalpius.onmicrosoft.com
CheckDevicePlatforms -Username user@thalpius.onmicrosoft.com
CheckCloudApps -Username user@thalpius.onmicrosoft.com
CheckAll -Username user@thalpius.onmicrosoft.com
```

# Screenshots

![Alt text](/Screenshots/Microsoft-Azure-AD-Conditional-Access-Validator-01.jpg?raw=true "Azure AD Conditional Access Validator")

![Alt text](/Screenshots/Microsoft-Azure-AD-Conditional-Access-Validator-02.jpg?raw=true "Azure AD Conditional Access Validator")
