# Application (client) ID, Tenant ID, and Client Secret
$appId = 'c86f4078-69c6-4db1-8c5b-5c4bc706ae0c'
$tenantId = '00f0544d-ba8c-45a7-8f03-17701fc50e91'
$clientSecret = 'XGs8Q~Co.YOdVIDuxPKEH.Ni8aqJIXpkEQTZQbOr'

# Token endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Get the token
$body = @{
    client_id     = $appId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body
$token = $response.access_token


$smtpServer = "turks-co-nz.mail.protection.outlook.com"
$smtpPort = 25
$emailFrom = "QuarantineNotification@turks.co.nz"
$emailTo = "admin@turks.co.nz"
$subject = "Sales E-mail in Quarantine"

# Get the messages from the quarantine for specific time from
$messages = get-QuarantineMessage | Where-Object { $_.ReceivedTime -gt (get-date).addMinutes(-30)  } 

#Inspect message headers for original To: address
$messagesHeaders = $messages| Get-QuarantineMessageHeader | Where-Object { $_.header -like '*To: admin@turks*' }

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
        Hi Sales Team,

        This is a notfication to let you know e-mail addresed to Sales@turks.co.nz or sales@turkspoultry.co.nz have been caught in the quarantine.
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
            Authorization = "Bearer $token"
            "Content-Type" = "application/json"
        }

    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/QuarantineNotification@turkspoultry.co.nz/sendMail" -Headers $headers -Body $emailBody -Method Post
    }
}

