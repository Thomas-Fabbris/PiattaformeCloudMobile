import { MongoClient } from 'mongodb';
import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";
import * as cheerio from 'cheerio';

// Initialize the clients outside the handler to be reused across invocations.
const mongo = new MongoClient(process.env.MONGO_URI);
const sagemaker = new SageMakerRuntimeClient({ region: "us-east-1" });

/**
 * Fetches the transcript from a given TED talk URL.
 * This function is taken from your first script to get the transcript using a URL.
 * @param {string} baseUrl - The base URL of the TED talk.
 * @returns {Promise<string>} The extracted transcript text.
 */
async function fetchTranscript(baseUrl) {
  // Ensure the URL points to the transcript page
  const transcriptUrl = baseUrl.endsWith('/') ? `${baseUrl}transcript` : `${baseUrl}/transcript`;

  console.log(`Fetching transcript from: ${transcriptUrl}`);
  const response = await fetch(transcriptUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch transcript. Status: ${response.status}`);
  }
  const html = await response.text();
  const $ = cheerio.load(html);

  let transcriptText = '';

  // Attempt to parse structured JSON-LD data first
  const scriptTag = $('script[type="application/ld+json"]');
  if (scriptTag.length > 0) {
    const jsonData = scriptTag.html();
    if (jsonData) {
      try {
        const data = JSON.parse(jsonData);
        if (data && data.transcript) {
          transcriptText = data.transcript;
        }
      } catch (e) {
        console.error("Failed to parse JSON-LD data.", e);
      }
    }
  }

  // Fallback to scraping visible text if JSON-LD fails
  if (!transcriptText) {
    console.log("JSON-LD transcript not found. Falling back to HTML scraping.");
    transcriptText = $('div[role="button"][aria-disabled="false"] > span').map((i, el) => $(el).text()).get().join(' ').replace(/\s\s+/g, ' ').trim();
  }

  if (!transcriptText) {
    throw new Error("Transcript content is empty or could not be found on the page.");
  }

  // The transcript is returned without slicing to let the QG model use the full context.
  return transcriptText;
}

/**
 * Generates questions from a transcript using the QG-E2E SageMaker endpoint.
 * @param {string} transcript - The text to generate questions from.
 * @returns {Promise<string[]>} A list of generated questions.
 */
async function generateQuestions(transcript) {
  const payload = {
    inputs: transcript,
    parameters: {
      max_length: 128,
      do_sample: true,
      temperature: 0.8,
      top_k: 50,
      top_p: 0.95
    }
  };
  const command = new InvokeEndpointCommand({
    EndpointName: 'QG-E2E', // Question Generation endpoint
    ContentType: 'application/json',
    Body: Buffer.from(JSON.stringify(payload))
  });
  const response = await sagemaker.send(command);
  const body = Buffer.from(response.Body).toString();
  const parsed = JSON.parse(body);

  if (!Array.isArray(parsed) || !parsed[0]?.generated_text) {
    throw new Error("Invalid response from SageMaker (QG-E2E)");
  }

  const generatedText = parsed[0].generated_text;
  // Split the generated string into individual questions
  return generatedText
    .split(/[.?!]/)
    .map(q => q.trim())
    .filter(q => q.length > 10); // Filter out very short, likely incomplete, questions
}

/**
 * Masks a word in a question to create a fill-in-the-blank exercise.
 * @param {string} question - The original question.
 * @returns {string} The question with a word replaced by '[MASK]'.
 */
function maskQuestion(question) {
  const parts = question.split(' ');
  // Find a reasonably long word to mask
  const index = parts.findIndex(w => w.length > 4);
  if (index >= 0) {
    parts[index] = '[MASK]';
  }
  return parts.join(' ');
}

/**
 * Gets fill-in-the-blank options for a masked question from the NLP-Exercise-Generator endpoint.
 * @param {string} maskedQuestion - The question containing a '[MASK]' token.
 * @returns {Promise<string[]>} A list of suggestion words.
 */
async function getFillMaskOptions(maskedQuestion) {
  const command = new InvokeEndpointCommand({
    EndpointName: 'NLP-Exercise-Generator', // Fill-Mask endpoint
    ContentType: 'application/json',
    Body: Buffer.from(JSON.stringify({ inputs: maskedQuestion }))
  });
  const response = await sagemaker.send(command);
  const body = Buffer.from(response.Body).toString();
  const predictions = JSON.parse(body);

  // Extract the predicted word from the full sequence
  return predictions.map(p => {
    const completed = p.sequence;
    const words = maskedQuestion.split(' ');
    const maskIndex = words.findIndex(w => w === '[MASK]');
    const completedWords = completed.split(' ');
    return completedWords[maskIndex] || completedWords[0];
  });
}

// Main Lambda handler
export const handler = async (event) => {
  const { talk_id } = JSON.parse(event.body || '{}');

  if (!talk_id) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "talk_id is required." }),
    };
  }

  try {
    await mongo.connect();
    
    // STEP 1: Fetch the talk URL from the 'tedx_data_cleaned' collection
    const talksDb = mongo.db('unibg_tedx_2025'); // Database where talk URLs are stored
    const talksCollection = talksDb.collection('tedx_data_cleaned');
    console.log(`Searching for talk with ID: ${talk_id}`);
    const talkDocument = await talksCollection.findOne({ _id: talk_id });

    if (!talkDocument || !talkDocument.url) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: `Talk with ID ${talk_id} not found or has no URL.` }),
      };
    }
    const talk_url = talkDocument.url;
    console.log(`Found URL: ${talk_url}`);

    // STEP 2: Fetch the transcript using the URL
    const transcript = await fetchTranscript(talk_url);
    if (!transcript || transcript.length < 20) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Fetched transcript is too short or missing." })
      };
    }

    // STEP 3: Generate questions from the transcript
    const questionList = await generateQuestions(transcript);
    if (!questionList.length) {
      throw new Error("No questions were generated from the transcript.");
    }

    const results = [];
    const exercisesDb = mongo.db('unibg_tedx_2025'); // Database where exercises are stored
    const exercisesCollection = exercisesDb.collection('exercises');

    // STEP 4: For each question, create a fill-in-the-blank exercise
    for (const question of questionList) {
      const masked = maskQuestion(question);
      const suggestions = await getFillMaskOptions(masked);

      const doc = {
        talk_id,
        original_question: question,
        masked_question: masked,
        options: suggestions,
        created_at: new Date()
      };
      
      const res = await exercisesCollection.insertOne(doc);
      results.push({ exercise_id: res.insertedId, masked_question: masked, options: suggestions });
    }

    // STEP 5: Return a successful response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Exercises generated successfully",
        count: results.length,
        exercises: results
      })
    };
  } catch (err) {
    console.error("An error occurred:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message || "An internal server error occurred." })
    };
  } finally {
    await mongo.close();
  }
};
