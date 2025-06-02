import joblib
import numpy as np
import pytest
import os


@pytest.fixture(scope="module")
def model():
    path = os.path.join("api", "mlflow_model", "model.pkl")
    return joblib.load(path)


def test_model_can_predict(model):
    api_path = os.path.join("api", "mlflow_model")
    vectorizer = joblib.load(os.path.join(api_path, "vectorizer.pkl"))
    model = joblib.load(os.path.join(api_path, "model.pkl"))

    sample = "Sample."
    X = vectorizer.transform([sample])  # Text to vector.

    prediction = model.predict(X)

    assert prediction.shape == (1,)
    assert isinstance(prediction[0], str)
