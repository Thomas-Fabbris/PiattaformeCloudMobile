import { MongoClient } from 'mongodb';
import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";
import * as cheerio from 'cheerio';

// The 'node-fetch' import has been removed. 
// We will use the native fetch API provided by the Node.js 18.x+ runtime.

// Initialize clients outside the handler for reuse across invocations
const mongo = new MongoClient(process.env.MONGO_URI);
const sagemaker = new SageMakerRuntimeClient({ region: "us-east-1" });

/**
 * Fetches the transcript from a given TED talk URL.
 * @param {string} baseUrl - The base URL of the TED talk.
 * @returns {Promise<string>} The extracted transcript text.
 */
async function fetchTranscript(baseUrl) {
  // Ensure the URL points to the transcript page
  const transcriptUrl = baseUrl.endsWith('/') ? `${baseUrl}transcript` : `${baseUrl}/transcript`;
  
  console.log(`Fetching transcript from: ${transcriptUrl}`);
  // This now uses the native fetch provided by the Lambda runtime
  const response = await fetch(transcriptUrl); 
  if (!response.ok) {
    throw new Error(`Failed to fetch transcript. Status: ${response.status}`);
  }
  const html = await response.text();
  const $ = cheerio.load(html);
  
  let transcriptText = '';

  // **Primary Method: Parse structured JSON-LD data**
  // This is more robust than scraping HTML classes, which can change frequently.
  const scriptTag = $('script[type="application/ld+json"]');
  if (scriptTag.length > 0) {
    const jsonData = scriptTag.html();
    if (jsonData) {
      try {
        const data = JSON.parse(jsonData);
        // The full transcript is available in this structured data.
        if (data && data.transcript) {
           transcriptText = data.transcript;
        }
      } catch (e) {
        console.error("Failed to parse JSON-LD data.", e);
      }
    }
  }

  // **Fallback Method: Scrape the visible transcript text**
  // This is used if the JSON-LD data is not available or fails to parse.
  if (!transcriptText) {
    console.log("JSON-LD transcript not found. Falling back to HTML scraping.");
    // This selector targets the individual text segments of the transcript.
    transcriptText = $('div[role="button"][aria-disabled="false"] > span').map((i, el) => $(el).text()).get().join(' ').replace(/\s\s+/g, ' ').trim();
  }
  
  if (!transcriptText) {
    throw new Error("Transcript content is empty or could not be found on the page.");
  }
  
  // Return the first 500 characters to stay within SageMaker limits
  return transcriptText.slice(0, 500);
}

/**
 * Generates a fill-in-the-blank exercise using a SageMaker NLP model.
 * @param {string} transcript - The transcript text to process.
 * @returns {Promise<{question: string, options: string[]}>} The generated question and answer options.
 */
async function generateExercise(transcript) {
  // Create a fill-in-the-blank question by masking the first long word
  const question = transcript.replace(/\b(\w{5,})\b/, '[MASK]');

  const payload = JSON.stringify({ inputs: question });

  const command = new InvokeEndpointCommand({
    EndpointName: 'NLP-Exercise-Generator', // Make sure this endpoint name is correct
    ContentType: 'application/json',
    Body: Buffer.from(payload)
  });

  console.log("Invoking SageMaker endpoint...");
  const response = await sagemaker.send(command);
  const responseBody = Buffer.from(response.Body).toString();
  const predictions = JSON.parse(responseBody);
  
  // Format the predictions into the desired structure
  return {
    question: question,
    options: predictions.map(p => p.sequence)
  };
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
    const db = mongo.db('unibg_tedx_2025');
    
    // STEP 1: Fetch talk URL from the 'tedx_data_cleaned' collection
    const talksCollection = db.collection('tedx_data_cleaned');
    console.log(`Searching for talk with ID: ${talk_id}`);
    const talkDocument = await talksCollection.findOne({ _id: talk_id });

    if (!talkDocument || !talkDocument.url) {
      console.error(`Talk with ID ${talk_id} not found or has no URL.`);
      return {
        statusCode: 404, // Not Found
        body: JSON.stringify({ error: `Talk with ID ${talk_id} not found or does not have a URL.` }),
      };
    }
    
    const talk_url = talkDocument.url;
    console.log(`Found URL: ${talk_url}`);

    // STEP 2: Fetch transcript using the retrieved URL
    const transcript = await fetchTranscript(talk_url);

    // STEP 3: Generate the exercise using SageMaker
    const exercise = await generateExercise(transcript);
    
    // STEP 4: Save the generated exercise to the 'exercises' collection
    const exercisesCollection = db.collection('exercises');
    const result = await exercisesCollection.insertOne({
      talk_id,
      talk_url, // Save the URL for reference
      transcript_snippet: transcript, // Renamed for clarity
      question: exercise.question,
      options: exercise.options,
      created_at: new Date()
    });
    console.log(`Exercise saved with ID: ${result.insertedId}`);

    // STEP 5: Return a successful response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Exercise generated successfully",
        exercise_id: result.insertedId,
        question: exercise.question,
        options: exercise.options
      })
    };

  } catch (err) {
    console.error("An error occurred:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message || "An internal server error occurred." })
    };
  } finally {
    // Ensure the MongoDB connection is closed
    await mongo.close();
  }
};
