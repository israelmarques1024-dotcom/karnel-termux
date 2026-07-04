# Veo 3 SDK

Google's most advanced video generation model. Python SDK for the Gemini API / Vertex AI.

## Installation

```bash
omni install ai --veo3
```

## Usage

```python
from google import genai
client = genai.Client()
response = client.models.generate_videos(
    model="veo-3.1",
    prompt="A golden retriever running on a beach"
)
```

**Command (CLI):** `veo3` (SDK wrapper)

**Links:**
- Google AI Studio: https://aistudio.google.com
- Vertex AI: https://console.cloud.google.com/vertex-ai
- SDK: `pip install google-genai`

## Authentication

```bash
gcloud auth application-default login
# or set GOOGLE_API_KEY environment variable
```

**Note:** Veo 3 requires a Google Cloud project with billing enabled and the Vertex AI API enabled.
