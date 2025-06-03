const mongoose = require('mongoose');
/**
 * URL Validator Function
 * @param {string} url - The URL string to validate.
 * @returns {boolean} - True if the URL is valid, false otherwise.
 */
const urlValidator = function(url) {
  if (!url) { // Allow empty or null if not 'required'
    return true;
  }
  try {
    const validatedUrl = new URL(url);
    return ['http:', 'https:'].includes(validatedUrl.protocol);
  } catch (e) {
    return false;
  }
};

const talk_schema = new mongoose.Schema({
  _id: {
    type: String,
    required: [true, 'id is required']
  },
  title: String,
  url: {
    type: String,
    required: [true, 'URL is required.'],
    validate: {
      validator: urlValidator,
      message: props => `${props.value} is not a valid website URL. Please ensure it starts with http:// or https://`
    }
  },
  description: String,
  duration: {
    type: Number
  },
  publishedAt: Date,
  speakers: String,
  tags: [String],
  related_video_ids: [String] 
}, { 
  collection: 'tedx_data_cleaned'
});

module.exports = mongoose.model('talk', talk_schema);
