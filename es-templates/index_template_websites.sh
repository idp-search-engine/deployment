curl -XPUT "http://elasticsearch-master:9200/_index_template/websites" -H 'Content-Type: application/json' -d'
{
  "template": {
    "settings": {
      "number_of_replicas": 2
    },
    "mappings": {
      "dynamic": "strict",
      "_source": {
        "enabled": true,
        "includes": [],
        "excludes": []
      },
      "_routing": {
        "required": false
      },
      "properties": {
        "url": {
          "type": "object",
          "dynamic": true
        },
        "original_url": {
          "type": "keyword"
        },
        "text": {
          "type": "text"
        }
      }
    }
  },
  "index_patterns": [
    "websites-*",
    "websites"
  ]
}'