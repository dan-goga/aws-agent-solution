"""Agent tool Lambda: a mock unit-price estimator.

Invoked synchronously by the backend's LangChain agent via
`boto3` `lambda:InvokeFunction` (not exposed through API Gateway, not
triggered by an event source). Demonstrates the agent calling out to an
external system for a fact it doesn't know from its own training.

Expected event: {"item": "ec2-t3-medium", "quantity": 5}
Success response: {"item", "unit_price", "quantity", "total"}
Unknown-item response: {"error", "known_items"}
"""

PRICE_TABLE = {
    "ec2-t3-medium": 0.0416,
    "ec2-t3-small": 0.0208,
    "ec2-t4g-medium": 0.0336,
    "s3-standard-gb": 0.023,
    "dynamodb-write-request-unit": 0.00000125,
    "lambda-invocation": 0.0000002,
}


def lambda_handler(event, context):
    item = str(event.get("item", "")).strip().lower()
    quantity = event.get("quantity", 1)

    try:
        quantity = float(quantity)
    except (TypeError, ValueError):
        return {"error": f"quantity must be a number, got {quantity!r}"}

    unit_price = PRICE_TABLE.get(item)
    if unit_price is None:
        return {
            "error": f"no pricing data for '{item}'",
            "known_items": sorted(PRICE_TABLE),
        }

    return {
        "item": item,
        "unit_price": unit_price,
        "quantity": quantity,
        "total": round(unit_price * quantity, 8),
    }
