import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';
import { generateQuestions, maskQuestion, getFillMaskOptions } from "./questions.mjs"
import fetchTranscript from './transcript.mjs';

dotenv.config({ path: './variables.env' });

const mongo = new MongoClient(process.env.MONGO_URI);

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
    const talksCollection = db.collection('tedx_data_cleaned');
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

    const transcript = await fetchTranscript(talk_url);
    if (!transcript || transcript.length < 20) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Fetched transcript is too short or missing." })
      };
    }

    const questionList = await generateQuestions(transcript);
    if (!questionList.length) {
      throw new Error("No questions were generated from the transcript.");
    }

    const results = [];
    const exercisesCollection = db.collection('exercises');

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