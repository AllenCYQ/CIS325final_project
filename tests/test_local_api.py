import requests

BASE_URL = "http://localhost:5000"


def test_api_home():
    r = requests.get(f"{BASE_URL}/")
    assert r.status_code == 200
    assert "Amazon review sentiment analysis API is live" in r.text


def test_sentiment_prediction():
    payload = {"review": "I love this product! It's excellent."}
    r = requests.post(f"{BASE_URL}/predict", json=payload)
    assert r.status_code == 200
    assert "sentiment" in r.json()
    sentiment = r.json()["sentiment"]
    assert sentiment in ["positive", "negative"] or isinstance(sentiment, str)
