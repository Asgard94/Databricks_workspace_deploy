# Databricks notebook source
import requests
import json

# COMMAND ----------

def send_slack_messages(webhook_url, channel, messages):
  """
  Sends a list of messages to Slack using the provided webhook URL.
  Args:
    webhook_url (str): The Slack Incoming Webhook URL.
    channel (str): The Slack channel to send the messages to (e.g., "#your-channel").
    messages (list): A list of message content to send to Slack.
  """

  blocks = []

  for message in messages:
    block = {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": message
      }
    }

    blocks.append(block)

  payload = {
    "channel": channel,
    "blocks": blocks
  }

  headers = {
    "Content-Type": "application/json"
  }

  response = requests.post(webhook_url, json=payload, headers=headers)

  if response.status_code != 200:
    raise ValueError(f"Error sending Slack messages: {response.text}")

# COMMAND ----------

webhook_url = dbutils.secrets.get(scope = "third_party_credentials", key = "slack.webhook")
channel = "#git_integration"

messages = [
  "Hello from Databricks!",
  "This is a test message.",
  "Another message example."
]

send_slack_messages(webhook_url, channel, messages)
