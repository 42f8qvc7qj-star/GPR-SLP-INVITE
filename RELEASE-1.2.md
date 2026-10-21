# SLP INVITE 1.2 — Installatie en updates

1. Commit alle bestanden naar de bestaande GitHub-repository. GitHub Actions bouwt de Windows-installatiebestanden.
2. Download het Actions-artifact en installeer de **Setup.exe** op de studiopc. De portable EXE heeft geen betrouwbare automatische update-installatie.
3. Publiceer bij iedere release **Setup.exe**, de bijbehorende **.blockmap** en **latest.yml** samen op een publiek bereikbaar HTTPS-adres. De GitHub-repository kan privé blijven. Het updateadres moet de map-URL zijn die eindigt op `/`.
4. Vul dat HTTPS-adres in onder Admin → Applicatie-updates. Daarna kan de app updates controleren en downloaden. Het updatebestand wordt pas geïnstalleerd na toestemming.
5. Een toekomstige release moet een hogere semver-versie in package.json hebben. Bouw en publiceer opnieuw alle updatebestanden.

**Let op:** De automatische updater is geïmplementeerd maar werkt pas nadat een echte HTTPS-updatebron is ingericht. `updates.example.invalid` is een niet-werkende placeholder voor de buildmetadata. Gebruik de ingestelde update-URL in de app. De installer is niet digitaal ondertekend; Windows kan SmartScreen tonen.

**SMS:** Twilio-gegevens worden lokaal opgeslagen, de token versleuteld via Electron safeStorage. Het beheerwachtwoord is lokaal per Windows-profiel. SMS gebruikt de betaalde Twilio API. De app registreert uitsluitend geaccepteerde verzendverzoeken, geen bezorgbevestiging.

**URL-verkorting:** optioneel via de externe dienst is.gd; de sessielink wordt met deze dienst gedeeld. Als dit niet lukt, blijft de originele link beschikbaar.

**Lettertypen:** meegeleverd onder assets/fonts; controleer de licentievoorwaarden voordat de app breder wordt verspreid.
