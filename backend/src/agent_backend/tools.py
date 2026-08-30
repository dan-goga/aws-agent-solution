from __future__ import annotations

import json
import time
from typing import Any

import boto3
from boto3.dynamodb.conditions import Key
from langchain_core.tools import tool

from .config import settings

_lambda_client = boto3.client("lambda", region_name=settings.aws_region)
_dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
_sessions_table = _dynamodb.Table(settings.dynamodb_table_name)


@tool
def estimate_cost(item: str, quantity: float = 1) -> str:
    """Estimate the cost of an AWS resource by name and quantity.

    Use this whenever the user asks how much something would cost, e.g.
    "how much would 5 t3.medium instances cost?" -> item="ec2-t3-medium",
    quantity=5. Known items: ec2-t3-medium, ec2-t3-small, ec2-t4g-medium,
    s3-standard-gb, dynamodb-write-request-unit, lambda-invocation.
    """
    payload = json.dumps({"item": item, "quantity": quantity}).encode("utf-8")
    response = _lambda_client.invoke(
        FunctionName=settings.lambda_tool_function_name,
        InvocationType="RequestResponse",
        Payload=payload,
    )
    result: dict[str, Any] = json.loads(response["Payload"].read())
    return json.dumps(result)


def save_turn(session_id: str, role: str, content: str) -> None:
    _sessions_table.put_item(
        Item={
            "session_id": session_id,
            "message_ts": int(time.time() * 1000),
            "role": role,
            "content": content,
        }
    )


def get_history(session_id: str, limit: int = 20) -> list[dict[str, Any]]:
    response = _sessions_table.query(
        KeyConditionExpression=Key("session_id").eq(session_id),
        ScanIndexForward=True,
        Limit=limit,
    )
    return response.get("Items", [])
