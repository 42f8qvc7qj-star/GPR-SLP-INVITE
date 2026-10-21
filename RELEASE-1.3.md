# GPR SLP INVITE 1.3.0 — Spryng SMS

- Twilio verwijderd en vervangen door Spryng v2 (`https://api.spryng.nl/v2/messages`).
- Admin > SMS: accountreferentie, afzender, API-sleutel, bericht, daglimiet, Spryng-linkverkorting.
- Standaard accountreferentie `SPNL0000396`, afzender `GPR Sport`; controleer deze voordat je live sms verstuurt.
- Spryng-verkorting gebruikt `[shorten: <originele SessionLink URL>]` in het SMS-bericht.
- API-sleutel wordt versleuteld met Electron safeStorage opgeslagen. Bestaande Twilio-tokens worden bij het opslaan van Admin-instellingen uit settings.json verwijderd.
- WhatsApp en optionele is.gd-linkverkorting blijven ongewijzigd.
- Een geaccepteerde SMS is niet per se bezorgd. Live verzending niet getest.
- Auto-update werkt pas nadat een bereikbare HTTPS-updatefeed is geconfigureerd; deze ZIP richt geen updatehosting in.

## Installatie
Upload alle bestanden en verborgen map `.github` naar je GitHub-repository. Start de workflow `Build Windows` onder Actions. Download het build-artifact. Controleer in Admin de Spryng-instellingen en voer eerst een test naar een eigen telefoon uit.

## Veiligheid
De Spryng API-sleutel wordt niet meegeleverd. Vul deze op de Windows-computer in onder Admin. Plaats de sleutel nooit in GitHub of screenshots.
