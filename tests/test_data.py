import pandas as pd
import pytest
import os


@pytest.fixture(scope="module")
def data():
    path = os.path.join("model", "1429_1.csv")
    return pd.read_csv(path, low_memory=False)


def test_data_not_empty(data):
    assert not data.empty, "Dataset should not be empty"


def test_columns_exist(data):
    expected = {"reviews.numHelpful", "reviews.rating", "reviews.text"}
    assert expected.issubset(set(data.columns)), (
        f"Missing expected columns: {expected - set(data.columns)}"
    )
