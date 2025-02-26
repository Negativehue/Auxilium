from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

# Fetch API key from environment variable
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("❌ API Key is missing! Set it in the environment variables.")

# API Endpoint
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateText?key={GEMINI_API_KEY}"

@app.route('/generate', methods=['POST'])
def generate_summary_and_reviewer():
    try:
        # Parse JSON request
        data = request.json
        summary_type = data.get("summary_type")
        reviewer_type = data.get("reviewer_type")
        extracted_text = data.get("extracted_text")

        # Validate required parameters
        if not summary_type or not reviewer_type or not extracted_text:
            return jsonify({"error": "Missing required parameters"}), 400

        # Construct the prompt
        prompt = f"Summarize the following text in {summary_type} format and generate a {reviewer_type} reviewer:\n\n{extracted_text}"

        # Send request to Gemini API
        response = requests.post(
            GEMINI_API_URL,
            headers={"Content-Type": "application/json"},
            json={"contents": [{"parts": [{"text": prompt}]}]},
        )

        # Handle API response
        if response.status_code == 200:
            result = response.json()

            # Extract AI response safely
            ai_response = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", None)
            if not ai_response:
                return jsonify({"error": "Invalid AI response format."}), 500

            return jsonify({"response": ai_response})

        else:
            return jsonify({"error": "AI service unavailable, please try again later."}), 500

    except Exception as e:
        return jsonify({"error": f"Server Error: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
