const functions = require('firebase-functions');
const admin = require('firebase-admin');
const FormData = require('form-data');
const fetch = require('node-fetch');

admin.initializeApp();

/**
 * Cloud Function to send emails via Mailgun API
 * Triggered when a document is created in the 'mail' collection
 */
exports.sendMailgunEmail = functions.firestore
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

      // Mailgun configuration - API key should be set via Firebase environment config
      // Run: firebase functions:config:set mailgun.apikey="YOUR_API_KEY"
      const MAILGUN_API_KEY = functions.config().mailgun?.apikey || process.env.MAILGUN_API_KEY;
      const MAILGUN_DOMAIN = 'goldenoaks.golf';

      if (!MAILGUN_API_KEY) {
        throw new Error('Mailgun API key not configured. Set via: firebase functions:config:set mailgun.apikey="YOUR_KEY"');
      }
      const MAILGUN_API_URL = `https://api.mailgun.net/v3/${MAILGUN_DOMAIN}/messages`;

      // Prepare form data for Mailgun API
      const form = new FormData();
      form.append('from', mailData.from || `Golden Oaks Golf League <noreply@${MAILGUN_DOMAIN}>`);

      // Handle 'to' field (can be array or string)
      if (Array.isArray(to)) {
        to.forEach(recipient => form.append('to', recipient));
      } else {
        form.append('to', to);
      }

      form.append('subject', subject);

      if (html) {
        form.append('html', html);
      }
      if (text) {
        form.append('text', text);
      }

      // Optional reply-to
      if (mailData.replyTo) {
        form.append('h:Reply-To', mailData.replyTo);
      }

      // Send email via Mailgun API
      console.log('Sending email via Mailgun API...');
      const response = await fetch(MAILGUN_API_URL, {
        method: 'POST',
        headers: {
          'Authorization': 'Basic ' + Buffer.from(`api:${MAILGUN_API_KEY}`).toString('base64'),
          ...form.getHeaders()
        },
        body: form
      });

      const responseData = await response.json();

      if (!response.ok) {
        throw new Error(`Mailgun API error: ${JSON.stringify(responseData)}`);
      }

      console.log('Email sent successfully:', responseData);

      // Update Firestore document with delivery status
      await snap.ref.update({
        delivery: {
          state: 'SUCCESS',
          startTime: admin.firestore.FieldValue.serverTimestamp(),
          endTime: admin.firestore.FieldValue.serverTimestamp(),
          info: {
            messageId: responseData.id,
            response: responseData.message
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
