const mongoose = require('mongoose');

const talk_schema = new mongoose.Schema({
    _id: String,
    title: String,
    url: String,
    description: String,
    speakers: String,
    comprehend_analysis: mongoose.Schema.Types.Mixed
}, { collection: 'tedx_data_cleaned' });

module.exports = mongoose.model('talk', talk_schema);
