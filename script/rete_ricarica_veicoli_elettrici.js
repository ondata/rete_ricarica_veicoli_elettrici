const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    // Attiva il protocollo del devtools su questa pagina
    await page.target().createCDPSession();

    // Cattura le risposte JSON
    const responses = [];

    // Svuota la cartella di output prima di iniziare
    const outputDirectory = path.join(__dirname, 'output');
    if (fs.existsSync(outputDirectory)) {
        fs.readdirSync(outputDirectory).forEach((file) => {
            const filePath = path.join(outputDirectory, file);
            fs.unlinkSync(filePath);
            console.log(`Eliminato ${file}`);
        });
    }

    page.on('response', async (response) => {
        const request = response.request();
        const url = request.url();

        // Controlla se l'URL corrisponde a quello desiderato
        if (url.includes('https://api.portal.piattaformaunicanazionale.it/v1/chargepoints/public/search')) {
            try {
                const responseText = await response.text();
                // Controlla se il corpo della risposta è valido
                if (responseText.trim()) {
                    responses.push(responseText);
                }
            } catch (error) {
                console.error('Errore durante il caricamento del corpo della risposta:', error.message);
            }
        }
    });

    // Abilita la registrazione del traffico di rete tramite DevTools
    await page.goto('https://www.piattaformaunicanazionale.it/idr');
    await page.evaluate(() => {
        const devtools = window.devtools = window.open('about:blank');
        devtools.opener = null;
        devtools.location = 'chrome-devtools://devtools/bundled/devtools_app.html';
        devtools.postMessage = message => window.postMessage(message, '*');
        window.addEventListener('message', event => devtools.postMessage(event.data, '*'));
    });

    // Attendi che il traffico di rete si calmi
    await waitForNetworkIdle(page, 10000); // Attendi 10 secondi

    // Salva le risposte JSON in file nella directory 'output'
    if (!fs.existsSync(outputDirectory)) {
        fs.mkdirSync(outputDirectory);
    }

    responses.forEach((response, index) => {
        const fileName = `response_${index}_${Date.now()}.json`;
        const filePath = path.join(outputDirectory, fileName);
        fs.writeFileSync(filePath, response);
        console.log(`Salvato ${fileName}`);
    });

    // Chiudi il browser
    await browser.close();

    console.log('Salvataggio completato. Browser chiuso.');
})();

async function waitForNetworkIdle(page, timeout) {
    let lastRequestTime = Date.now();
    let idleTimeout;

    function onRequest() {
        lastRequestTime = Date.now();
        clearTimeout(idleTimeout);
        idleTimeout = setTimeout(checkIdle, timeout);
    }

    function checkIdle() {
        if (Date.now() - lastRequestTime >= timeout) {
            console.log('Il traffico di rete è calmo. Continua...');
        } else {
            clearTimeout(idleTimeout);
            idleTimeout = setTimeout(checkIdle, timeout);
        }
    }

    page.on('request', onRequest);

    await new Promise(resolve => setTimeout(resolve, timeout));

    page.off('request', onRequest);
}
