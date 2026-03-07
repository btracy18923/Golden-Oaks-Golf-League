const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { Resend } = require('resend');

admin.initializeApp();

/**
 * Cloud Function to send emails via Resend API
 * Triggered when a document is created in the 'mail' collection
 */
exports.sendEmail = functions.firestore
  .document('mail/{mailId}')
  .onCreate(async (snap, context) => {
    const mailData = snap.data();
    const mailId = context.params.mailId;

    console.log(`Processing email document: ${mailId}`);
    console.log('Email data:', JSON.stringify(mailData, null, 2));

    try {
      // Validate required fields
      if (!mailData.to || !mailData.message) {
        throw new Error('Missing required fields: to or message');
      }

      const { to, message } = mailData;
      const { subject, text, html } = message;

      if (!subject || (!text && !html)) {
        throw new Error('Missing required message fields: subject or text/html');
      }

      // Resend configuration - API key from environment variable or Firebase config
      const RESEND_API_KEY = process.env.RESEND_API_KEY || functions.config().resend?.apikey;

      if (!RESEND_API_KEY) {
        throw new Error('Resend API key not configured');
      }

      // Initialize Resend with API key
      const resend = new Resend(RESEND_API_KEY);

      // Prepare email message
      const emailMessage = {
        from: mailData.from || 'Golden Oaks Golf League <noreply@goldenoaks.golf>',
        to: Array.isArray(to) ? to : [to], // Resend expects an array
        subject: subject,
      };

      // Add text content if provided
      if (text) {
        emailMessage.text = text;
      }

      // Add HTML content if provided
      if (html) {
        emailMessage.html = html;
      }

      // Add reply-to if provided
      if (mailData.replyTo) {
        emailMessage.reply_to = mailData.replyTo;
      }

      // Send email via Resend
      console.log('Sending email via Resend API...');
      const response = await resend.emails.send(emailMessage);

      console.log('Email sent successfully:', response);

      // Update Firestore document with delivery status
      await snap.ref.update({
        delivery: {
          state: 'SUCCESS',
          startTime: admin.firestore.FieldValue.serverTimestamp(),
          endTime: admin.firestore.FieldValue.serverTimestamp(),
          info: {
            messageId: response.data?.id || response.id,
            response: 'Email sent successfully'
          }
        }
      });

      console.log(`Email document ${mailId} updated with delivery status`);
      return null;

    } catch (error) {
      console.error('Error sending email:', error);

      // Update Firestore document with error status
      await snap.ref.update({
        delivery: {
          state: 'ERROR',
          startTime: admin.firestore.FieldValue.serverTimestamp(),
          endTime: admin.firestore.FieldValue.serverTimestamp(),
          error: error.message,
          info: {
            error: error.toString()
          }
        }
      });

      console.log(`Email document ${mailId} updated with error status`);
      return null;
    }
  });
