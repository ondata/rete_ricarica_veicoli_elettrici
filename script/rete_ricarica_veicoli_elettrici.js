const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
    console.log('Avvio dello script...');

    const browser = await puppeteer.launch();
    console.log('Browser avviato con successo.');

    const page = await browser.newPage();
    console.log('Pagina creata con successo.');

    // Attiva il protocollo del devtools su questa pagina
    await page.target().createCDPSession();
    console.log('Protocollo DevTools attivato.');

    // Cattura le risposte JSON
    const responses = [];

    // Svuota la cartella di output prima di iniziare
    const outputDirectory = path.join(__dirname, 'output');
    console.log('Percorso della cartella di output:', outputDirectory);

    if (fs.existsSync(outputDirectory)) {
        fs.readdirSync(outputDirectory).forEach((file) => {
            const filePath = path.join(outputDirectory, file);
            fs.unlinkSync(filePath);
            console.log(`Eliminato ${file}`);
        });
    } else {
        console.log('La cartella di output non esiste. Verrà creata.');
    }

    page.on('response', async (response) => {
        const request = response.request();
        const url = request.url();

        // Modifica l'URL di interesse
        if (url.includes('https://api.portal.piattaformaunicanazionale.it/v1/chargepoints/public/map/search')) {
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

    // Naviga verso la pagina di interesse
    console.log('Navigazione verso la pagina...');
    await page.goto('https://www.piattaformaunicanazionale.it/idr');
    console.log('Pagina caricata.');

    // Attendi che il traffico di rete si calmi
    console.log('Attesa del traffico di rete...');
    await waitForNetworkIdle(page, 30000); // Attendi 30 secondi

    // Salva le risposte JSON in file nella directory 'output'
    console.log('Salvataggio delle risposte JSON...');
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
    console.log('Chiusura del browser...');
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
