GPR SLP INVITE 1.4.0

- SessionLinkPRO accountkeuze en beheer in Admin
- Eén gedeelde SessionLink-browseromgeving; accountkeuze via dropdown. Bij een afwijkende login wordt veilig gestopt zodat de medewerker kan wisselen.
- Automatisch Create Session Link en Copy Link to Clipboard (Playwright)
- Voorgrond herstellen na aanmaak
- Voorzichtige sessiecontrole: geen garantie van gastlink-geldigheid
- Bestaande WhatsApp deep-link en Spryng SMS behouden. WhatsApp wordt NIET automatisch verzonden omdat ontvangerverificatie in de Windows-app nog niet betrouwbaar is.

Bouwen: npm install && npm run dist (Windows).
Updates: handmatig installeren blijft mogelijk; automatische updates vereisen een ingestelde HTTPS-updatefeed.
