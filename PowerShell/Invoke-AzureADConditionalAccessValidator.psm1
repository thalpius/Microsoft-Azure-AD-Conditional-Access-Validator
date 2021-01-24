<#
 
.SYNOPSIS
  This script validates the most common Conditional Access policies in Microsoft 365.
 
.DESCRIPTION
 
  This script validates the most common Conditional Access policies in Microsoft 365 including
  Multi-Factor Authentication for Device Platforms.

  Note: Internet Explorer's first-launch configuration must be completed before running the script.
 
.PARAMETER
 
  Username of an account which is able to login without the need to change their password.
 
.EXAMPLE

  CheckLegacyAuth -Username user@thalpius.onmicrosoft.com
  CheckDevicePlatforms -Username user@thalpius.onmicrosoft.com
  CheckCloudApps -Username user@thalpius.onmicrosoft.com
  CheckAll -Username user@thalpius.onmicrosoft.com

.INPUTS
 
  Username needs to be given as an argument.
  Password will be prompted for the given user.
 
.OUTPUTS
 
  Output will be shown in the terminal/console.
 
.NOTES
 
  Version:        0.1
  Author:         R. Roethof
  Creation Date:  24/01/2021
  Website:        https://thalpius.com
  Purpose/Change: Initial script development

#>
 
#-------------------------------------------[Declarations]-----------------------------------------

$UserAgentArrayList = New-Object -TypeName 'System.Collections.ArrayList';

#--------------------------------------------[Functions]-------------------------------------------

function Request {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [parameter(Mandatory = $false, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [system.URI]$Password
    )
    begin {
    }
    process {
        try {
            $GetSession = Invoke-WebRequest -Uri 'https://outlook.office365.com' -SessionVariable O365Portal -UserAgent $UserAgent.UserAgent
            
            $originalRequest = $GetSession.content -split "," 
            $originalRequest = ($originalRequest | Select-String -Pattern "ctx=")[0]
            $originalRequest = $originalRequest -split "ctx="
            $originalRequest = $originalRequest[1].TrimEnd('/"')
            
            $flowToken = $GetSession.content -split ","
            $flowToken = $flowToken | Select-String -Pattern "sFT`""
            $flowToken = $flowToken -split "sFT`":`""
            $flowToken = $flowToken[1].TrimEnd('/"')
            
            $ctx = $originalRequest
            
            $UserRequestBody = @{
                username                       = "$username"
                isOtherIdpSupported            = "true"
                checkPhones                    = "true"
                isRemoteNGCSupported           = "true"
                isCookieBannerShown            = "false"
                isFidoSupported                = "true"
                originalRequest                = "$originalRequest"
                country                        = "NL"
                forceotclogin                  = "false"
                isExternalFederationDisallowed = "false"
                isRemoteConnectSupported       = "false"
                federationFlags                = "0"
                isSignup                       = "false"
                flowToken                      = "$flowToken"
                isAccessPassSupported          = "true"
            } | ConvertTo-Json
            
            $UserRequest = Invoke-WebRequest -Uri ("https://login.microsoftonline.com/common/GetCredentialType?mkt=en-US") -WebSession $O365Portal  -UserAgent $UserAgent.UserAgent -Method POST -Body $UserRequestBody
            
            $AuthenticationRequestBody = @{
                i13               = '0'
                login             = "$username"
                loginfmt          = "$username"
                type              = '11'
                LoginOptions      = '3'
                lrt               = ""
                lrtPartition      = ""
                hisRegion         = ""
                hisScaleUnit      = ""
                passwd            = "$password"
                ps                = '2'
                psRNGCDefaultType = ""
                psRNGCEntropy     = ""
                psRNGCSLK         = ""
                canary            = ""
                ctx               = "$ctx"
                hpgrequestid      = ""
                flowToken         = "$flowToken"
                PPSX              = ""
                NewUser           = '1'
                FoundMSAs         = ""
                fspost            = '0'
                i21               = '0'
                CookieDisclosure  = '0'
                IsFidoSupported   = '1'
                isSignupPost      = '0'
                i2                = '1'
                i17               = ""
                i18               = ""
                i19               = '65474'
            }
            
            $AuthenticationRequest = Invoke-WebRequest -Uri ("https://login.microsoftonline.com/common/login") -WebSession $O365Portal -UserAgent $UserAgent.UserAgent -Method POST -Body $AuthenticationRequestBody
            if ($O365Portal.Cookies.GetCookies("https://login.microsoftonline.com").Name -like "ESTSAUTHPERSISTENT") {
                Write-Host "- User $username is able to authenticate to the Microsoft 365 portal with the following device platform:" $UserAgent.FriendlyName -ForegroundColor Green
                if ($AuthenticationRequest.Content -match "Stay signed in") {
                    Write-Host "- No Multi-Factor Authentication seems to be enabled for user $username using the device platform:" $UserAgent.FriendlyName -ForegroundColor Red
                }
                elseif ($AuthenticationRequest.Content -match "Verify your identity") {
                    Write-Host -ForegroundColor Red "- Multi-Factor Authentication for user $username seems to be enabled" -ForegroundColor Green
                }
            }
            else {
                Write-Host "- User $username is not able to authenticate to the Microsoft 365 portal using the following device platform:" $UserAgent.FriendlyName -ForegroundColor Red
            }
        }
        catch {
            Write-Host $_.Exception
            exit
        }
    }
    end {
        if ($?) {
        }
    }
}
function CheckLegacyAuth {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [parameter(Mandatory = $false, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [system.URI]$Password
    )
    begin {
        Write-Host "Start checking Legacy Authentication..." -ForegroundColor Yellow
        if (!($Password)) {
            $SecurePassword = Read-Host "Enter the password for user $UserName" -AsSecureString
            $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
        }
    }
    process {
        try {
            $ActiveSyncUri = ("https://outlook.office365.com/Microsoft-Server-ActiveSync?oQAJBBDfboQVTBIbhj7NNo75D05WBMWIRs8LV2luZG93c01haWw=")
            $EncodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Username, $Password)))
            $Headers = @{
                'Authorization' = "Basic $($EncodedCredentials)"
            }
        
            try {
                $ActiveSyncRequest = Invoke-WebRequest -Uri $ActiveSyncUri -Headers $Headers -Method Post
                if ($ActiveSyncRequest.StatusCode -eq 200) {
                    Write-Host "- User $username is able to authenticate to the Microsoft 365 portal using Legacy authentication clients: Exchange ActiveSync clients" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "- User $username is not able to authenticate to the Microsoft 365 portal using Legacy authentication clients: Exchange ActiveSync clients" -ForegroundColor Red
            }
        }
        catch {
            Write-Host $_.Exception
            exit
        }
    }
    end {
        if ($?) {
            Write-host "Start checking Legacy Authentication completed successfully..." -ForegroundColor Yellow
        }
    }
}
function CheckDevicePlatforms {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [parameter(Mandatory = $false, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [system.URI]$Password
    )
    begin {
        Write-Host "Start checking device platforms..." -ForegroundColor Yellow
        if (!($Password)) {
            $SecurePassword = Read-Host "Enter the password for user $UserName" -AsSecureString
            $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
        }
        $UserAgentArrayList.Clear()
        [void]$UserAgentArrayList.Add(@{"UserAgent" = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko)"; "FriendlyName" = "MacOS" })
        [void]$UserAgentArrayList.Add(@{"UserAgent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/18.17763"; "FriendlyName" = "Windows" })
        [void]$UserAgentArrayList.Add(@{"UserAgent" = "Mozilla/5.0 (Linux; Android 10; LIO-AL00) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.114 Mobile Safari/537.36"; "FriendlyName" = "Android" })
        [void]$UserAgentArrayList.Add(@{"UserAgent" = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1"; "FriendlyName" = "iOS" })
        [void]$UserAgentArrayList.Add(@{"UserAgent" = "Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0; NOKIA; Lumia 710)"; "FriendlyName" = "Windows Phone" })
        [void]$UserAgentArrayList.Add(@{"UserAgent" = "Mozilla/5.0 (Amiga; U; AmigaOS 1.3; en; rv:1.8.1.19) Gecko/20081204 SeaMonkey/1.1.14"; "FriendlyName" = "AmigaOS" })
    }
    process {
        try {
            foreach ($UserAgent in $UserAgentArrayList) {
                Request -UserName $UserName -Password $Password
            }
        }
        catch {
            Write-Host $_.Exception
            exit
        }
    }
    end {
        if ($?) {
            Write-host "Start checking device platforms completed successfully..." -ForegroundColor Yellow
        }
    }
}
function CheckCloudApps {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [parameter(Mandatory = $false, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [system.URI]$Password
    )
    begin {
        Write-Host "Start checking cloud apps..." -ForegroundColor Yellow
        if (!($Password)) {
            $SecurePassword = Read-Host "Enter the password for user $UserName" -AsSecureString
            $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
        }
    }
    process {
        try {
            $UserCloudAppsBody = @{
                'resource'   = 'https://management.core.windows.net'
                'username'   = $username
                'password'   = $password
                'client_id'  = '1950a258-227b-4e31-a9cf-717495945fc2'
                'scope'      = 'openid'
                'profile'    = 'offline_access'
                'grant_type' = 'password'
            }
            $CloudAppsHeaders = @{
                'Accept'       = 'application/json'
                'Content-Type' = 'application/x-www-form-urlencoded'
            }
            $AuthRequest = Invoke-WebRequest https://login.microsoftonline.com/Common/oauth2/token -Headers $CloudAppsHeaders -Method Post -Body $UserCloudAppsBody
            If ($AuthRequest.StatusCode -eq "200") {
                Write-Host "- User $username is not able to authenticate to Microsoft 365 using PowerShell" -ForegroundColor Green
            }
        }
        catch {
            Write-Host $_.Exception
            exit
        }
    }
    end {
        if ($?) {
            Write-host "Start checking cloud apps completed successfully..." -ForegroundColor Yellow
        }
    }
}
function CheckAll {
    Param(
        [parameter(Mandatory = $true, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [parameter(Mandatory = $false, HelpMessage = "Specify a username")]
        [ValidateNotNullOrEmpty()]
        [system.URI]$Password
    )
    begin {
        Write-Host "Start checking all Conditional Access policies..." -ForegroundColor Yellow
        $SecurePassword = Read-Host "Enter the password for user $UserName" -AsSecureString
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
    }
    process {
        try {
            CheckLegacyAuth -UserName $UserName -Password $Password
            CheckDevicePlatforms -UserName $UserName -Password $Password
            CheckCloudApps -UserName $UserName -Password $Password
        }
        catch {
            Write-Host $_.Exception
            exit
        }
    }
    end {
        if ($?) {
            Write-host "Start checking all Conditional Access policies completed successfully..." -ForegroundColor Yellow
        }
    }
}
