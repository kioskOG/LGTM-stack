How it works:

* prometheus.exporter.unix "node_exporter": This block tells Grafana Alloy to start an internal HTTP server (usually on port 80 or 8080 within the Alloy pod, depending on its overall configuration) that exposes Node Exporter metrics.

* discovery.relabel "node_exporter_relabel": This block discovers the Alloy pods themselves (which are now acting as Node Exporters) and applies labels to their metrics.

* prometheus.scrape "node_exporter_scrape": This block tells the Alloy agent to scrape its own internal Node Exporter endpoint (or the endpoint of other Alloy pods, if configured for distributed scraping) and then forward those metrics.

* prometheus.remote_write "central_prometheus": This block then sends the scraped metrics to your central Prometheus/Mimir/Thanos instance.