import * as cheerio from 'cheerio';
/**
 * Fetches the transcript from a given TEDX talk URL.
 * @param {string} baseUrl - The URL of the TEDX talk
 * @returns {Promise<string>} The extracted transcript
 */
export default async function fetchTranscript(baseUrl) {
    const transcriptUrl = baseUrl.endsWith('/') ? `${baseUrl}transcript` : `${baseUrl}/transcript`;
  
    console.log(`Fetching transcript from: ${transcriptUrl}`);
    const response = await fetch(transcriptUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch transcript. Status: ${response.status}`);
    }
    const html = await response.text();
    const $ = cheerio.load(html);
  
    let transcriptText = '';
  
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
  
    if (!transcriptText) {
      console.log("JSON-LD transcript not found. Falling back to HTML scraping.");
      transcriptText = $('div[role="button"][aria-disabled="false"] > span').map((i, el) => $(el).text()).get().join(' ').replace(/\s\s+/g, ' ').trim();
    }
  
    if (!transcriptText) {
      throw new Error("Transcript content is empty or could not be found on the page.");
    }
  
    return transcriptText.slice(0,8192);
  }
