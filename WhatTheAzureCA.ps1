function Send-WhatIfRequest {
    <#
    .SYNOPSIS
        Sends Azure Conditional Access "What If" requests to the Azure API as defined in the scenarios.json.
    .DESCRIPTION
        This functions it build to send an Azure Conditional Acces "What If" request to the Azure API 
        and returns a JSON string containing all policies applied to the respective user.
        Created by bi-sec 2023, fs.
    .PARAMETER headers
        HTTP-Headers for the HTTP-Request like Authorization Token (see "<REPLACE>" below). 
        Headers can be taken from the original What If POST-Request to the "Evaluation" file. 
    .PARAMETER body
        HTTP-Body for the HTTP-Request
    .LINK
        https://github.com/bi-sec-pub/WhatTheAzureCA
    .EXAMPLE
        $headers = @{
            "Authorization"="Bearer eyAF<REPLACE>"
            "x-ms-client-request-id"="acd<REPLACE>"
            "x-ms-client-request-id"="acd<REPLACE>"
        }

        The $body is a modified version of the HTTP-Payload created by Azure when executing a What If request.
        A sample config can be found in the linked GitHub-Repository
        
        Usage:
        Send-WhatIfRequest $headers $body
    #>
    
    param (
        [Parameter(Mandatory="true", Position=0)]
        [ValidateNotNullOrEmpty()]
        $headers,

        [Parameter(Mandatory="true", Position=1)]
        [ValidateNotNullOrEmpty()]
        $body
    )

    $uri = "https://main.iam.ad.ext.azure.com/api/WhatIf/Evaluate?"

    # Check if only $country or only $ipAddress is set
    if((!$body.country -and $body.ipAddress) -or ($body.country -and !$body.ipAddress)) {
        throw "If Variable country is set, ipAddress must also be set and vice versa."
    } 
        
    return (
        Invoke-WebRequest -Uri $uri `
        -UseBasicParsing `
        -Method POST `
        -Headers $headers `
        -ContentType "application/json" `
        -Body ($body | ConvertTo-Json -Depth 5 -Compress)
    )
}

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
# Replace the headers below where <REPLACE> is mentioned
# Infos can be taken by submitting a What If request via portal.azure.com

$headers = @{
"x-ms-client-session-id"="<REPLACE>"
"x-ms-command-name"="AuthenticationStrength%20-%20GetUserAuthenticationPolicy"
"Accept-Language"="de"
"Authorization"="Bearer ey<REPLACE>"
"x-ms-effective-locale"="de.de-de"
"Accept"="*/*"
"Referer"=""
"x-ms-client-request-id"="<REPLACE>"
}

#########################################################
#########################################################
###################### USER CONFIG ######################
######################     END     ######################
#########################################################
#########################################################

if (!$args[0] -or $args[0] -eq $null) {
    throw "No file given. Please define a config file for headers as first and the scenarios.json as second parameter"
}

# Read command line argument
$filepath = $args[0]

$scenarios = Get-Content -Raw (Resolve-Path -Path $filepath)

# Deserialize JSON
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")        
$jsonserializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
$scenarios = $jsonserializer.DeserializeObject($scenarios)

Clear-Host

foreach ($scenario in $scenarios.GetEnumerator()) {

    # Write Scenario Name
    Write-Host "$($scenario.name)"
            
    $response = Send-WhatIfRequest $headers $scenario.config

    # Check if response is not empty
    if (!$response) {
        throw "No response, please check Exception Message. Maybe your auth token and ids are invalid."
    }

    $policies = ($response.Content | ConvertFrom-Json).policies
    

    Write-Host "- Applied Policies & Controls:"


    # Loop through all policies
    foreach ($policy in $policies.GetEnumerator()) {
    
        Write-Host "-- $($policy.policyName)"
        Write-Host "--- applied: $($policy.applied)" 

        
        $condition = ""
        $blockAccess = $policy.controls.blockAccess

        # Loop through policy controls
        foreach ($control in $policy.controls.PSObject.Properties) {

            if($control.Value -eq $true) {

                $condition += $control.Name + ","

                Write-Host "--- $($control.Name): $($control.Value)"

            }

        }
        
        # Loop through policy filters
        foreach ($filter in $policy.filters.PSObject.Properties) {

            if($filter.Value -eq $true) {

                $condition += $filter.Name + ","

                Write-Host "--- $($filter.Name): $($filter.Value)"

            }
        }

        
        # Loop through policy session controls
        foreach ($sessionControl in $policy.sessionControls.PSObject.Properties) {

            if($sessionControl.Value -eq $true) {

                $condition += $sessionControl.Name + ","

                Write-Host "--- $($sessionControl.Name): $($sessionControl.Value)"

            }
        }
            

        $condition = $condition.TrimEnd(",")

        $csv += [PSCustomObject]@{
            "scenario" = $scenario.name
            "user" = $scenario.user
            "policy" = $policy.policyName
            "applied" = $policy.applied
            "blockAccess" = $blockAccess
            "condition" = $condition
        }
            
        # Rate limit to avoid getting blocked
        Start-Sleep -Milliseconds 300 
        Write-Host "`n"
    }
}

$csv | Export-CSV -NoTypeInformation -Delimiter ";" -Path $csvOutPath