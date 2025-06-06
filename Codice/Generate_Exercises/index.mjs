import { MongoClient } from 'mongodb';
import { InvokeEndpointCommand, SageMakerRuntimeClient } from "@aws-sdk/client-sagemaker-runtime";
import * as cheerio from 'cheerio';

// Viene utilizzata l'API fetch nativa di Node.js.

// Inizializza i client fuori dall'handler per riutilizzarli tra le invocazioni
const mongo = new MongoClient(process.env.MONGO_URI);
const sagemaker = new SageMakerRuntimeClient({ region: "us-east-1" });

/**
 * Estrae la trascrizione da un dato URL di un talk TED.
 * @param {string} baseUrl - L'URL di base del talk TED.
 * @returns {Promise<string>} Il testo della trascrizione estratto.
 */
async function fetchTranscript(baseUrl) {
  // Assicura che l'URL punti alla pagina della trascrizione
  const transcriptUrl = baseUrl.endsWith('/') ? `${baseUrl}transcript` : `${baseUrl}/transcript`;
  
  console.log(`Recupero trascrizione da: ${transcriptUrl}`);
  // Ora utilizza la fetch nativa fornita dal runtime Lambda
  const response = await fetch(transcriptUrl); 
  if (!response.ok) {
    throw new Error(`Recupero trascrizione fallito. Status: ${response.status}`);
  }
  const html = await response.text();
  const $ = cheerio.load(html);
  
  let transcriptText = '';

  // Metodo Primario: Analisi dei dati strutturati JSON-LD
  const scriptTag = $('script[type="application/ld+json"]');
  if (scriptTag.length > 0) {
    const jsonData = scriptTag.html();
    if (jsonData) {
      try {
        const data = JSON.parse(jsonData);
        // La trascrizione completa è disponibile in questi dati strutturati.
        if (data && data.transcript) {
           transcriptText = data.transcript;
        }
      } catch (e) {
        console.error("Analisi dei dati JSON-LD fallita.", e);
      }
    }
  }

  // Metodo Secondario (Fallback): Estrazione del testo visibile
  if (!transcriptText) {
    console.log("Trascrizione JSON-LD non trovata. Utilizzo del metodo di scraping HTML.");
    // Questo selettore punta ai segmenti di testo individuali della trascrizione.
    transcriptText = $('div[role="button"][aria-disabled="false"] > span').map((i, el) => $(el).text()).get().join(' ').replace(/\s\s+/g, ' ').trim();
  }
  
  if (!transcriptText) {
    throw new Error("Il contenuto della trascrizione è vuoto o non è stato trovato nella pagina.");
  }
  
  // La trascrizione viene nuovamente troncata per rispettare i limiti del modello SageMaker
  return transcriptText.slice(0, 500);
}

/**
 * Genera un esercizio "fill-in-the-blank" usando un modello NLP di SageMaker.
 * @param {string} transcript - Il testo della trascrizione da elaborare.
 * @returns {Promise<{question: string, options: string[], answer: string}>} La domanda generata, le opzioni e la risposta corretta.
 */
async function generateExercise(transcript) {
  const match = transcript.match(/\b(\w{5,})\b/);
  if (!match) {
    throw new Error("Could not find a suitable word to mask in the transcript.");
  }
  
  const originalWord = match[0];
  const question = transcript.replace(originalWord, '[MASK]');

  const payload = JSON.stringify({ inputs: question });

  const command = new InvokeEndpointCommand({
    EndpointName: 'NLP-Exercise-Generator', // Assicurati che il nome dell'endpoint sia corretto
    ContentType: 'application/json',
    Body: Buffer.from(payload)
  });

  console.log("Invocazione dell'endpoint SageMaker...");
  const response = await sagemaker.send(command);
  const responseBody = Buffer.from(response.Body).toString();
  const predictions = JSON.parse(responseBody);
  
  if (!Array.isArray(predictions)) {
      throw new Error("Invalid response from SageMaker endpoint.");
  }

  // *** MODIFICA: Estrae solo la parola predetta (token_str) invece dell'intera sequenza. ***
  const distractors = predictions
    .map(p => p.token_str.trim())
    .filter((word, index, self) => 
        word && 
        word.toLowerCase() !== originalWord.toLowerCase() && 
        self.indexOf(word) === index
    );

  // Crea la lista finale di opzioni, includendo la risposta corretta e i distrattori
  let options = [originalWord, ...distractors.slice(0, 3)];

  // Mescola le opzioni
  for (let i = options.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [options[i], options[j]] = [options[j], options[i]];
  }
  
  return {
    question: question,
    options: options,
    answer: originalWord // La risposta corretta è la parola che abbiamo mascherato
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
    
    // STEP 1: Recupera l'URL del talk dalla collezione 'tedx_data_cleaned'
    const talksCollection = db.collection('tedx_data_cleaned');
    console.log(`Ricerca talk con ID: ${talk_id}`);
    const talkDocument = await talksCollection.findOne({ _id: talk_id });

    if (!talkDocument || !talkDocument.url) {
      console.error(`Talk con ID ${talk_id} non trovato o senza URL.`);
      return {
        statusCode: 404, // Not Found
        body: JSON.stringify({ error: `Talk con ID ${talk_id} non trovato o senza un URL.` }),
      };
    }
    
    const talk_url = talkDocument.url;
    console.log(`URL trovato: ${talk_url}`);

    // STEP 2: Recupera la trascrizione usando l'URL trovato
    const transcript = await fetchTranscript(talk_url);

    // STEP 3: Genera l'esercizio usando SageMaker
    const exercise = await generateExercise(transcript);
    
    // STEP 4: Salva l'esercizio generato nella collezione 'exercises'
    const exercisesCollection = db.collection('exercises');
    // *** MODIFICA: Salva anche la risposta corretta e rimuove transcript_snippet. ***
    const result = await exercisesCollection.insertOne({
      talk_id,
      talk_url, // Salva l'URL per riferimento
      question: exercise.question,
      options: exercise.options,
      answer: exercise.answer,
      created_at: new Date()
    });
    console.log(`Esercizio salvato con ID: ${result.insertedId}`);

    // STEP 5: Restituisce una risposta di successo
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Esercizio generato con successo",
        exercise_id: result.insertedId,
        question: exercise.question,
        options: exercise.options
        // La risposta corretta non viene inviata al client
      })
    };

  } catch (err) {
    console.error("Si è verificato un errore:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message || "Si è verificato un errore interno del server." })
    };
  } finally {
    // Assicura che la connessione a MongoDB venga chiusa
    await mongo.close();
  }
};
