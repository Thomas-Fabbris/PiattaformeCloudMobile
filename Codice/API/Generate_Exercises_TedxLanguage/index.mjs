import {
    MongoClient
} from 'mongodb';
import dotenv from 'dotenv';
import {
    generateQuestions,
    maskQuestion,
    getFillMaskOptions
} from "./questions.mjs";
import fetchTranscript from './transcript.mjs';

dotenv.config({
    path: './variables.env'
});
const mongoClient = new MongoClient(process.env.MONGO_URI);

export const handler = async (event, context) => {
    const {
        talk_id
    } = JSON.parse(event.body || '{}');
    context.callbackWaitsForEmptyEventLoop = false;

    if (!talk_id) {
        return {
            statusCode: 400,
            body: JSON.stringify({
                error: "talk_id is required."
            })
        };
    }

    try {
        await mongoClient.connect();
        const db = mongoClient.db('unibg_tedx_2025');
        const exercisesCollection = db.collection('exercises');

        const existingExercises = await exercisesCollection.find({
            talk_id: talk_id
        }).toArray();
        if (existingExercises.length > 0) {
            console.log(`Trovati ${existingExercises.length} esercizi esistenti.`);
            return {
                statusCode: 200,
                body: JSON.stringify({
                    exercises: existingExercises
                })
            };
        }

        const talksCollection = db.collection('tedx_data_cleaned');
        const talkDocument = await talksCollection.findOne({
            _id: talk_id
        });

        if (!talkDocument || !talkDocument.url) {
            throw new Error(`Talk with ID ${talk_id} not found or has no URL.`);
        }

        const transcript = await fetchTranscript(talkDocument.url);
        if (!transcript || transcript.length < 20) {
            throw new Error("Fetched transcript is too short or missing.");
        }

        const questionList = await generateQuestions(transcript);
        if (!questionList.length) {
            throw new Error("No questions were generated from the transcript.");
        }

        const exercisesToSave = await Promise.all(
            questionList.map(async (question) => {
                const masked = maskQuestion(question);
                const options = await getFillMaskOptions(masked);
                let correctAnswer = '';

                for (const opt of options) {
                    if (masked.replace('[MASK]', opt) === question) {
                        correctAnswer = opt;
                        break;
                    }
                }

                return {
                    talk_id,
                    original_question: question,
                    masked_question: masked,
                    options: options,
                    correctAnswer: correctAnswer,
                    created_at: new Date()
                };
            })
        );

        if (exercisesToSave.length > 0) {
            await exercisesCollection.insertMany(exercisesToSave);
            console.log(`${exercisesToSave.length} esercizi salvati nel DB.`);
        }

        return {
            statusCode: 200,
            body: JSON.stringify({
                exercises: exercisesToSave
            })
        };

    } catch (err) {
        console.error("An error occurred:", err);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: err.message || "An internal server error occurred."
            })
        };
    }
};
