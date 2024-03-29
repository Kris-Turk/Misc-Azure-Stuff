param($Timer)

#############################################################  Variables ##############################################################################

# Frequency App is being run in minutes
$frequency = 30

# Managed Identity
$tenantName = "contoso.onmicrosoft.com"
$MI_ClientID = "xxxxxxxx-f32d-4643-953f-xxxxxxxxxxxx"

# Notification Email variables
$emailFrom = "quarantine@contoso.com"
$emailTo = "bob@contoso.com"
$subject = "Quarantine Notification"
$emailGreeting = "Hi Kris,"

# This pattern searches message headers which allows to also search for distribution Groups
$headerSearchPattern = "*To: kris@*"


#####################################################################################################################################################

Write-Host "Connecting to EXO..." 
try{
    Connect-ExchangeOnline -ManagedIdentity -Organization $tenantName -ManagedIdentityAccountId $MI_ClientID
    Write-Host 'Connected'
}
catch {
    # create response body in JSON format 
    $body = $_.Exception.Message | ConvertTo-Json -Compress -Depth 10
    Write-Host $body
    Write-Host "Failed to Connect"
    break   
}

$resourceURI = "https://graph.microsoft.com/"
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01&client_id=$MI_ClientID"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token



# Get the messages from the quarantine for specific time from
$messages = get-QuarantineMessage | Where-Object { $_.ReceivedTime -gt (get-date).addMinutes(-$frequency)  }
$messageCount = $messages.count

Write-Host "There are $messageCount in the quarantine in the last $frequency minutes"

#Inspect message headers for original To: address
$messagesHeaders = $messages| Get-QuarantineMessageHeader | Where-Object { $_.header -like $headerSearchPattern }

$count = $messagesHeaders.count


Write-Host "$count messages found that match the header search pattern"

# Iterate through emails that match criteria for Urgent notifcation
foreach($mh in $messagesHeaders){

    $m = Get-QuarantineMessage -Identity $mh.Identity
    if ($m.ReleaseStatus -eq "NOTRELEASED"){
        
        # Format the email body
        $time = $m.ReceivedTime.ToString('dd-MM-yyyy HH:mm')
        $from = $m.SenderAddress
        $sub = $m.Subject
        $type = $m.type
        $bodyContent = @"
        $emailGreeting

        This is a notfication to let you know an e-mail addressed to email alias matching pattern $headerSearchPattern has been caught in the quarantine.
        If this e-mail is expected or should be released please contact IT support.

        Recieved Time: $time
        From: $from
        Subject: $sub
        Type: $type

        Kind Regards
        Quarantine Notification Bot
"@
   
        

        # Send the email using Graph API
        $emailBody = @{
            message = @{
                subject = $subject
                toRecipients = @(
                    @{
                        emailAddress = @{
                            address = $emailTo
                        }
                    }
                )            
                body = @{
                    contentType = "Text"
                    content     = $bodyContent
                }
            }
            saveToSentItems = $false
        } | ConvertTo-Json -Depth 4

        $headers = @{
            Authorization = "Bearer $accessToken"
            "Content-Type" = "application/json"
        }

    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$emailFrom/sendMail" -Headers $headers -Body $emailBody -Method Post
    }
}

