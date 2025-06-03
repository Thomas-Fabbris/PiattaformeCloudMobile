const connect_to_db = require('./db');

// GET BY ID HANDLER

const talk = require('./Talk');

module.exports.get_watch_next_by_id = async (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    let body = {};
    if (event.body) {
        body = JSON.parse(event.body);
    }

    if (!body.id) {
        return callback(null, {
            statusCode: 500,
            headers: { 'Content-Type': 'text/plain' },
            body: 'Could not fetch the talks. Id is null.'
        });
    }

    body.doc_per_page = body.doc_per_page || 10;
    body.page = body.page || 1;

    try {
        await connect_to_db();
        console.log('=> get_all talks');


        return callback(null, {
            statusCode: 200,
            body: JSON.stringify(watchNext)
        });

    } catch (err) {
        console.error('Error fetching talks:', err);
        return callback(null, {
            statusCode: err.statusCode || 500,
            headers: { 'Content-Type': 'text/plain' },
            body: 'Could not fetch the talks.'
        });
    }
};
