# WhatTheAzureCA
# Overview
A tool to automate Conditional Access What If-scenarios using the Azure Graph API.

### Table of content
1. [Overview](#overview)
2. [Structures](#structures)
3. [Usage](#usage)
<br><br>

# Structures
## ... of a scenario:
- `name` = Name of the scenario; Can be set to any name of your choice
- `user` = CA User to test policy
- `config` = WhatIf HTTP-Request Config

```javascript
{
    "name": "User: <Username> | Platform: <Platform> | IP: <IP> | Country: <Country> | Device: isCompliant | ServicePrincipal: Any Cloud apps",
    "user": "<Username>",
    "config": { ... }
}
```
<br>

## ... of the config
The config is the HTTP-Request **Payload**, which is sent by *WhatIfBlade* when executing a *What If* request.
```javascript
"config": {
    "conditions": {
        "conditions": {
            "clientAppsV2": { ... },
            "devicePlatforms": { ... },
            "deviceState": { ... },
            "locations": { ... },
            "minSigninRisk": { ... },
            "minUserRisk": { ... },
            "servicePrincipalRiskLevels": { ... },
        "servicePrincipals": { ... },
        "users": { ... }
    },
    "country": "<Country>",         
    "device": { ... },
    "ipAddress": "<IP>"
}
```
Please keep in mind that the `country` and `ipAddress` parameters are **dependent** on each other. If one of them is set, the other one must be set as well. But they dont have to be set in a configuration, they are ***optional***.
<br><br>

# Usage
This script was created to loop through different kinds of predefined scenarios to receive a short and compact overview of the policy configuration of your tenant.<br>
You can find a "[Sample Scenarios JSON](./sample_scenarios.json)"-File with predefined scenarios in the repository. These scenarios are a modified version of the WhatIf-Config originally created by Azure.
<br>
<br>

**Before you can use the Samples** you **have to replace** the *user ids* and *ip addresses* with valid user ids of your tenant and valid ip addresses. For example you could use one internal ip address and one external which is not associated with your tenant as reference. The properties can be found through a `"_comment"` property above them, like shown below:
```javascript
[...]
    "included": {
        "groupIds": [],
        "_comment": "Please replace sample userId with a valid one",
        "userIds": ["00000000-0000-0000-0000-111111111111"]
    } 

    [...]

    "_comment": "Please replace sample ipAddress with a valid one",
    "ipAddress": "127.0.0.2"

[...]
```
<br>

In the [Powershell script](./WhatTheAzureCA.ps1) you can find the following code snippet beginning a line 55. This section is for user related configurations and also must be modified before the first usage. The `$dirPath` can set to any destination as you please. The default is set to the same directory, from which the script will be executed.

<br>

The `$headers` are needed for authorization at the Azure API. You can copy them from the request like shown in the [video](#how-to-receive-the-the-headers) down below.

```powershell
#########################################################
#########################################################
######################             ######################
###################### USER CONFIG ######################
######################             ######################
#########################################################
#########################################################

$dirPath = (Resolve-Path -Path "./").Path

# CSV Location
$csvOutPath = $dirPath + "/Azure-WhatIf-Summary.csv"

# Request headers
$headers = @{
"x-ms-client-session-id"="acd<REPLACE>"
"x-ms-command-name"="AuthenticationStrength%20-%20GetUserAuthenticationPolicy"
"Accept-Language"="de"
"Authorization"="Bearer eyAF<REPLACE>"
"x-ms-effective-locale"="de.de-de"
"Accept"="*/*"
"Referer"=""
"x-ms-client-request-id"="acd<REPLACE>"
}

#########################################################
#########################################################
###################### USER CONFIG ######################
######################     END     ######################
#########################################################
#########################################################
```
<br>

#### How to receive the the headers
https://github.com/bi-sec-pub/WhatTheAzureCA/assets/111047625/c6c38297-6386-4572-8381-76c8f8267e1f



### Executing the script
After replacing all needed values you can execute the script and it will automaticly loop through the predefined scenarios and print the applied status of the policies in the console and in additions creates a *CSV* file, like the [sample](Azure-WhatIf-Summary.csv) one. 


### Troubleshooting
Sometimes to script throws exceptions while executing it. Please read the exception message for further details. If the time between copying the headers and executing the script is too long it may be possible that this also causes a different message besides the "Invalid creditials ..." one

If you have difficulties running the example please contact us at whattheazureca@bi-sec.de
