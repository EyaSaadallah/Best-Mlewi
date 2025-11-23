import 'package:mailer/mailer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // Credentials are now loaded from .env file
  static String get _senderEmail => dotenv.env['EMAIL_USERNAME'] ?? '';
  static String get _senderPassword => dotenv.env['EMAIL_PASSWORD'] ?? '';

  static final EmailService _instance = EmailService._internal();

  factory EmailService() {
    return _instance;
  }

  EmailService._internal();

  /// Send an email with the given subject and body
  Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? htmlBody,
  }) async {
    // If credentials are not set, log error and return false
    if (_senderEmail.contains('example.com') ||
        _senderPassword.contains('password-here')) {
      debugPrint(
        '❌ EMAIL CONFIGURATION ERROR: Please set _senderEmail and _senderPassword in email_service.dart',
      );
      return false;
    }

    // Configure the SMTP server (using Gmail as default example)
    // For other providers, use SmtpServer(host, port: port, username: user, password: password)
    final smtpServer = gmail(_senderEmail, _senderPassword);

    // Create the message
    final message = Message()
      ..from = Address(_senderEmail, 'Best Mlewi App')
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body
      ..html = htmlBody;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('❌ Message not sent.');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error sending email: $e');
      return false;
    }
  }

  /// Send welcome email with credentials
  Future<bool> sendCredentialsEmail({
    required String toEmail,
    required String password,
    required String firstName,
  }) async {
    final subject = 'Welcome to Best Mlewi - Your Account Credentials';

    final textBody =
        '''
Hello $firstName,

Welcome to the Best Mlewi team! Your account has been successfully created.

Here are your login credentials:
--------------------------------
Email: $toEmail
Password: $password
--------------------------------

Please log in and change your password immediately.

Best regards,
Best Mlewi Management
''';

    final htmlBody =
        '''
<h1>Welcome to Best Mlewi!</h1>
<p>Hello <b>$firstName</b>,</p>
<p>Welcome to the team! Your account has been successfully created.</p>
<div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
  <h3>Your Login Credentials:</h3>
  <p><b>Email:</b> $toEmail</p>
  <p><b>Password:</b> $password</p>
</div>
<p><i>Please log in and change your password immediately.</i></p>
<p>Best regards,<br>Best Mlewi Management</p>
''';

    return await sendEmail(
      toEmail: toEmail,
      subject: subject,
      body: textBody,
      htmlBody: htmlBody,
    );
  }
}
