const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));
import * as cheerio from 'cheerio';
import { MongoClient } from 'mongodb';
import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";

const mongo = new MongoClient(process.env.MONGO_URI);
const sagemaker = new SageMakerRuntimeClient({ region: "us-east-1" });

export const handler = async (event) => {
  const { talk_id, talk_url } = JSON.parse(event.body || '{}');

  if (!talk_url || !talk_url.includes("ted.com/talks/")) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "URL TED non valido" }),
    };
  }

  try {
    await mongo.connect();
    const db = mongo.db('tedxlanguage');
    const collection = db.collection('exercises');
    
    const transcript = await fetchTranscript(talk_url);
    if (!transcript) throw new Error("Transcript non trovato.");

    const exercise = await generateExercise(transcript);
    
    const result = await collection.insertOne({
      talk_id,
      talk_url,
      transcript,
      question: exercise.question,
      options: exercise.options,
      created_at: new Date()
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Esercizio generato",
        exercise_id: result.insertedId,
        question: exercise.question,
        options: exercise.options
      })
    };

  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message })
    };
  } finally {
    await mongo.close();
  }
};

async function fetchTranscript(baseUrl) {
  const transcriptUrl = baseUrl.endsWith('/') ? `${baseUrl}transcript` : `${baseUrl}/transcript`;
  const response = await fetch(transcriptUrl);
  const html = await response.text();
  const $ = cheerio.load(html);
  const transcriptText = $('div.Grid__cell p').map((i, el) => $(el).text()).get().join(' ');
  return transcriptText.trim().slice(0, 500); // Limita per SageMaker
}

async function generateExercise(transcript) {
  const masked = transcript.replace(/\b(\w{5,})\b/, '[MASK]');

  const payload = JSON.stringify({ inputs: masked });

  const command = new InvokeEndpointCommand({
    EndpointName: 'NLP-Exercise-Generator', 
    ContentType: 'application/json',
    Body: Buffer.from(payload)
  });

  const response = await sagemaker.send(command);
  const body = Buffer.from(response.Body).toString();
  const predictions = JSON.parse(body);

  return {
    question: masked,
    options: predictions.map(p => p.sequence)
  };
}
