# GPR Sportradio | SLP INVITE

Windows Electron-app voor SessionLink Pro-uitnodigingen via WhatsApp.

## Starten
Installeer Node.js LTS op Windows. Open PowerShell in deze map:

    npm install
    npm start

## Windows .exe bouwen

    npm run dist

De installer en portable executable komen in `dist/`. Alternatief: plaats deze map in een privé-GitHub-repository en start de meegeleverde GitHub Actions workflow **Windows build**; download daarna de build artifact.

## Gebruik
1. Open SessionLink Pro in de browser en kopieer de actuele gastlink.
2. De app leest gekopieerde SessionLink Pro-links automatisch uit het Windows-klembord.
3. Vul gastnaam en nummer in, controleer bericht, klik **Open in WhatsApp**.
4. Controleer de ontvanger en verzend zelf in WhatsApp.

## Beveiliging en beperkingen
- Eerste gebruiker stelt het adminwachtwoord in (minimaal 10 tekens); geen standaardwachtwoord.
- Het adminwachtwoord wordt met scrypt en willekeurig salt gehasht. De app slaat de uitnodigingsgeschiedenis en actuele link lokaal op in de Electron-userData-map, **niet versleuteld**. Gebruik alleen op een vertrouwde Windows-account en ruim oude gegevens op.
- De adminvergrendeling beschermt instellingen in de app, niet tegen iemand met toegang tot de bestanden van de Windows-account. Voor echte multi-user beheerrechten is een server nodig.
- De geschiedenis vermeldt **Geopend in WhatsApp**, niet 'Verstuurd'. De app kan verzending niet bevestigen.
- De getoonde URL is de echte URL van SessionLink Pro; er wordt **geen verzonnen shortlink** gebruikt. Een eigen URL-verkorter vereist een vertrouwde redirectservice en domein.
- SMS is nog niet geïmplementeerd; toekomstige optie in admin.
- Alleen https-links op sessionlink.pro en slink.pro worden geaccepteerd. Pas de allowlist in `main.js` aan als jullie echte gastlinks een ander officieel domein gebruiken.
- Niet digitaal ondertekend; Windows SmartScreen kan een waarschuwing tonen. Test op een niet-productie-pc voordat je het in de live-studio inzet.
