import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";

const sagemaker = new SageMakerRuntimeClient({ region: "us-east-1" });

/**
 * Generates questions from a transcript using the QG-E2E SageMaker endpoint.
 * @param {string} transcript - The transcript to generate questions from
 * @returns {Promise<string[]>} A list of generated questions
 */
export async function generateQuestions(transcript) {
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
    EndpointName: 'QG-E2E',
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
return generatedText
    .split(/[.?!]/)
    .map(q => q.trim())
    .filter(q => q.length > 10); // Filter out very short, likely incomplete, questions
}

/**
 * Masks a word (reasonibily large) in a question to create a fill-in-the-blank exercise.
 * @param {string} question - The original question
 * @returns {string} The question with a word replaced by '[MASK]'.
 */
export function maskQuestion(question) {
const parts = question.split(' ');
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
export async function getFillMaskOptions(maskedQuestion) {
const command = new InvokeEndpointCommand({
    EndpointName: 'NLP-Exercise-Generator',
    ContentType: 'application/json',
    Body: Buffer.from(JSON.stringify({ inputs: maskedQuestion }))
});
const response = await sagemaker.send(command);
const body = Buffer.from(response.Body).toString();
const predictions = JSON.parse(body);

return predictions.map(p => {
    const completed = p.sequence;
    const words = maskedQuestion.split(' ');
    const maskIndex = words.findIndex(w => w === '[MASK]');
    const completedWords = completed.split(' ');
    return completedWords[maskIndex] || completedWords[0];
});
}