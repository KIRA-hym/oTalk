import json

with open('C:/otalk_app/firebase.json', 'r') as f:
    data = json.load(f)

data['hosting'] = {
  "public": "build/web",
  "ignore": [
    "firebase.json",
    "**/.*",
    "**/node_modules/**"
  ],
  "rewrites": [
    {
      "source": "**",
      "destination": "/index.html"
    }
  ]
}

with open('C:/otalk_app/firebase.json', 'w') as f:
    json.dump(data, f, indent=2)

print("Updated firebase.json")
