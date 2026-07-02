exports.handler = async (event) => {
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
    };

    if (event.httpMethod === 'OPTIONS') {
        return { statusCode: 200, headers: corsHeaders, body: '' };
    }

    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, headers: corsHeaders, body: 'Method Not Allowed' };
    }

    try {
        const { to, bcc, subject, text, html, recipients } = JSON.parse(event.body);

        // Individual send mode: send one email per address so each recipient
        // sees their own address in the To field (used for Email Blast)
        // Uses Resend batch API to send all emails in one request, avoiding Netlify's 10s timeout
        if (recipients && Array.isArray(recipients) && recipients.length > 0) {
            const batch = recipients.map(address => ({
                from: 'Golden Oaks Golf League <noreply@goldenoaks.golf>',
                to: [address],
                subject,
                ...(html ? { html, text: text || '' } : { text }),
            }));

            const resp = await fetch('https://api.resend.com/emails/batch', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(batch),
            });

            const sent = resp.ok ? recipients.length : 0;
            const failed = resp.ok ? 0 : recipients.length;
            return {
                statusCode: 200,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                body: JSON.stringify({ sent, failed }),
            };
        }

        // Standard single-send mode (ProShop, group emails, results, etc.)
        const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: 'Golden Oaks Golf League <noreply@goldenoaks.golf>',
                to,
                ...(bcc ? { bcc } : {}),
                subject,
                ...(html ? { html, text: text || '' } : { text }),
            }),
        });

        const body = await response.text();
        return {
            statusCode: response.status,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            body,
        };
    } catch (err) {
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ error: err.message }),
        };
    }
};
