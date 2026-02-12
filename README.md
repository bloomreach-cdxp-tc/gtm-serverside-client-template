# Bloomreach (Exponea) Client for Google Tag Manager Server Container

This client forwards requests from the **Bloomreach brweb.js SDK** (stream_id–based) through your GTM server container for first-party cookie tracking. It uses **Stream ID** (not project token) and supports the current Bloomreach API endpoints:

- **JS SDK**: `/js/brweb.min.js`
- **Tracking**: `/track/u/v1/batch?stream_id=...`
- **Web XP**: `/webxp/streams/{stream_id}/bundle`, `/webxp/streams/.../managed-tags/show`, `/webxp/streams/.../cookies/.../link-ids`, `/webxp/streams/.../script/.../modifications.min.js`, etc.

**Configuration:** Set **API endpoint** (e.g. `https://eu3-api.eng.bloomreach.com`), **Stream ID** (your stream UUID), and optionally the path used to serve the SDK (default `/js/brweb.min.js`).

Google Tag Manager templates in this repository are provided as a BETA feature and should not be used in production environments. 
We are providing the templates for technically advanced customers who understand the underlying code of the templates and are able to modify the template according to their needs. 
Bloomreach does not currently provide production-level support for any kind of usage of this template.


## Useful links

- https://docs.exponea.com/docs/1st-party-cookie-tracking-solutions#2-google-tag-manager-server-side-solution
