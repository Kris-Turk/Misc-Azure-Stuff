$smtpServer = "company-com.mail.protection.outlook.com"
$smtpFrom = "sales@company.com"
$smtpTo = "joe@company.com"
$messageSubject = "Testing SPAM"
$messageBody = "This is a test e-mail"

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($smtpFrom,$smtpTo,$messagesubject,$messagebody)

