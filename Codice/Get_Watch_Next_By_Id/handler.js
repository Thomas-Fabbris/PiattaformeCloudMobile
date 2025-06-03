const connect_to_db = require('./db');
const talk = require('./talk'); 

module.exports.get_watch_next_by_id = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    let body = {};
    if (event.body) {
        try {
            body = JSON.parse(event.body);
        } catch (parseError) {
            console.error('Error parsing event body:', parseError);
            return callback(null, {
                statusCode: 400, 
                headers: { 'Content-Type': 'text/plain' },
                body: 'Could not parse request body. Ensure it is valid JSON.'
            });
        }
    }

    if (!body.id) {
        console.log('Missing id in request body.');
        return callback(null, {
            statusCode: 400,
            headers: { 'Content-Type': 'text/plain' },
            body: 'Could not fetch related talks. Missing "id" in request body.'
        });
    }

     body.doc_per_page = body.doc_per_page || 10;
     body.page = body.page || 1;

    try {
        await connect_to_db();
        console.log(`=> Attempting to fetch watch next for talk ID: ${body.id}`);
        
        const mainTalk = await talk.findById(body.id); 
        
        if (!mainTalk) {
            console.log(`Main talk with ID '${body.id}' not found.`);
            return callback(null, {
                statusCode: 404, 
                headers: { 'Content-Type': 'text/plain' },
                body: `Main talk with ID '${body.id}' not found.`
            });
        }
        
        const relatedIds = mainTalk.related_video_ids;
        let relatedTalksDocuments = [];

        if (!relatedIds || relatedIds.length === 0) {
            console.log(`No related video IDs found for talk '${mainTalk.title || body.id}'. Returning empty array for related talks.`);
        } else {
            console.log(`Found related video IDs: ${relatedIds.join(', ')}. Fetching related talks...`);
            relatedTalksDocuments = await talk.find({
                _id: { $in: relatedIds }
            }).select('-related_video_ids');
            console.log(`Found ${relatedTalksDocuments.length} related talk document(s).`);
        }
        
        const responsePayload = { 
            mainTalkTitle: mainTalk.title || 'N/A', 
            relatedTalks: relatedTalksDocuments 
        };

        return callback(null, {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' }, 
            body: JSON.stringify(responsePayload)
        });

    } catch (err) {
        console.error('Error processing request for get_watch_next_by_id:', err);
        return callback(null, {
            statusCode: err.statusCode || 500,
            headers: { 'Content-Type': 'text/plain' },
            body: `Could not fetch related talks. Error: ${err.message || 'Internal server error.'}`
        });
    }
};
