$smtpServer = "kristurk-com.mail.protection.outlook.com"
$smtpFrom = "orders@kristurk.com"
$smtpTo = "sales@kristurk.com"
$messageSubject = "Testing SPAM"
$messageBody = "This is a test e-mail"

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($smtpFrom,$smtpTo,$messagesubject,$messagebody)

