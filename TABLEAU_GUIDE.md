# Tableau dashboard
1. Run the app once - `tableau/tableau_borrowings_flat.csv` (borrowings + item + student data in one table) is generated and refreshed after every rental/return.
2. Tableau -> Connect -> Text file -> `tableau_borrowings_flat.csv`.
3. Suggested sheets: Revenue by category (bar), Amount by month (line), department x weekday (heat map), payment method (pie), days distribution (histogram).
4. Combine into one Dashboard -> Publish to Tableau Public -> Share -> copy the Embed URL.
5. Paste it into `config.json` -> `"tableau_embed_url"` and reload the site. It appears in the Tableau section.
