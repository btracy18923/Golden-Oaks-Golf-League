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
        const { to, bcc, subject, text, html } = JSON.parse(event.body);

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
