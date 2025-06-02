from flask import Flask, request, jsonify
import pandas as pd
import joblib
import os

# Initializing Flask app.
app = Flask(__name__)

# Load vectorizer and model.
vectorizer = joblib.load(os.path.join("mlflow_model", "vectorizer.pkl"))
model = joblib.load(os.path.join("mlflow_model", "model.pkl"))


# Base URI route. This route will be used to test the API.
@app.route("/")
def home():
    return "Amazon review sentiment analysis API is live."


# API route for prediction.
@app.route("/predict", methods=["POST"])
def predict():
    try:
        # Making prediction call.
        review_text = request.json[
            "review"
        ]  # Expecting JSONic payload with "review" key.

        X = vectorizer.transform([review_text])  # Text to vector.

        prediction = model.predict(X)  # Submitting the prediction.

        # Returning prediction call.
        return jsonify({"sentiment": prediction[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


if __name__ == "__main__":
    import os

    port = int(os.environ.get("PORT", 5000))

    # 0.0.0.0 required for port to listen outside of the container.
    app.run(host="0.0.0.0", port=port)
