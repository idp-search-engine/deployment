curl -XPUT "http://elasticsearch-master:9200/_ingest/pipeline/website-pipeline" -H 'Content-Type: application/json' -d'
{
  "description": "Pipeline to process scraped web pages",
  "processors": [
    {
      "uri_parts": {
        "field": "original_url"
      },
      "html_strip": {
        "field": "text"
      }
    }
  ]
}'