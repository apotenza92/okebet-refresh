import requests
import os
import pandas as pd
import logging
import time
import datetime
import json
import msal
from sshtunnel import SSHTunnelForwarder
from dotenv import load_dotenv

load_dotenv()

# String variables = Replace with your own
tenant_id = os.getenv("TENANT_ID")
authority_url = os.getenv("AUTHORITY_URL") + tenant_id
client_id = os.getenv("CLIENT_ID")
client_secret = os.getenv("CLIENT_SECRET")
scope = [os.getenv("SCOPE")]

# https://learn.microsoft.com/en-us/power-bi/connect-data/asynchronous-refresh
# https://api.powerbi.com/v1.0/myorg/groups/{groupId}/datasets/{datasetId}/refreshes
workspace_id = os.getenv("WORKSPACE_ID")  # = group_id
dataset_id = os.getenv("DATASET_ID")
url = (
    "https://api.powerbi.com/v1.0/myorg/groups/"
    + workspace_id
    + "/datasets/"
    + dataset_id
    + "/refreshes"
)

ssh_tunnel = SSHTunnelForwarder(
    "54.79.64.88",
    ssh_username="bm",
    ssh_pkey=os.getenv("PRIVATE_KEY_PATH"),
    remote_bind_address=("replicated-db-api.okebet.com.au", 3306),
    local_bind_address=("localhost", 3309),
)


def configure_logging():

    # Ensure the logs directory exists
    if not os.path.exists("logs"):
        os.makedirs("logs")

    logs = os.listdir("logs")
    if len(logs) > 10:
        logs.sort()
        for log in logs[:-10]:
            os.remove(f"logs/{log}")

    # Configure logging
    logging.basicConfig(
        filename=f"logs/refresh_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log",
        filemode="w",
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d_%H-%M-%S",
        level=logging.INFO,
    )

    # Create a console handler and set its level to INFO
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)

    # Create a formatter and add it to the console handler
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    console_handler.setFormatter(formatter)

    # Add the console handler to the root logger
    logging.getLogger().addHandler(console_handler)

    logging.info(f"-------------DETAILS--------------------")
    logging.info(f"Initiated at : {datetime.datetime.now()}")
    logging.info(f"tenant_id = {tenant_id}")
    logging.info(f"authority_url = {authority_url}")
    logging.info(f"client_id = {client_id}")
    logging.info(f"client_secret = {client_secret}")
    logging.info(f"scope = {scope}")
    logging.info(f"workspace_id = {workspace_id}")
    logging.info(f"dataset_id = {dataset_id}")
    logging.info(f"base_url = {url}")
    logging.info(f"SSH Tunnel details: \n{ssh_tunnel}")
    logging.info(f"-----------------------------------------")


def start_ssh_tunnel():
    try:
        ssh_tunnel.start()
        if ssh_tunnel.is_active:
            logging.info("SSH tunnel successfully started.")
        else:
            logging.info("SSH tunnel failed to start.")
    except Exception as e:
        logging.info("Failed to start SSH tunnel.")
        logging.info(e)
    time.sleep(10)


def get_token_for_client(scope):
    app = msal.ConfidentialClientApplication(
        client_id, authority=authority_url, client_credential=client_secret
    )
    result = app.acquire_token_for_client(scopes=scope)
    if "access_token" in result:
        logging.info("Token acquired successfully.")
        return result["access_token"]
    else:
        logging.error(
            "Error in get_token_username_password:",
            result.get("error"),
            result.get("error_description"),
        )


configure_logging()
start_ssh_tunnel()
access_token = get_token_for_client(scope)
header = {"Content-Type": "application/json", "Authorization": f"Bearer {access_token}"}

# Make the POST request with the parameters in the body
params = {"type": "full"}
params_json = json.dumps(params)
api_call = requests.post(url=url, headers=header, data=params_json)
logging.info(f"Started refresh at : {datetime.datetime.now()}")
logging.info(f"Status code: {api_call.status_code}")
logging.info(
    "API headers:\n" + "\n".join(f"{k}: {v}" for k, v in api_call.headers.items())
)


# Get status of current api call to see if it's in progress or failed
def get_current_status():
    api_call = requests.get(url=url, headers=header)
    result = api_call.json()["value"]
    df = pd.DataFrame(
        result,
        columns=["requestID", "id", "refreshType", "startTime", "endTime", "status"],
    )
    return df.status[0]


# while the df.status[0] returns anything other than Completed, log the current status to the log file with current time. Do it for a maximum of 1 hour.

start_time = datetime.datetime.now()
max_time = start_time + datetime.timedelta(hours=1)

while True:
    current_status = get_current_status()
    if current_status == "Completed":
        logging.info(f"Refresh completed. Status: {current_status}")
        logging.info(f"Time to refresh: {datetime.datetime.now() - start_time}")
        break
    elif current_status == "Unknown":
        logging.info(
            f"Refresh in progress... (Status Unknown = In progress) Status: {current_status}"
        )
    elif current_status == "Failed":
        logging.error(f"Refresh failed. Status: {current_status}")
        break
    elif current_status == "Disabled":
        logging.error(f"Refresh disabled. Status: {current_status}")
        break
    else:
        logging.error(f"Unknown status. Status: {current_status}")
        break

    # Sleep before checking the status again
    time.sleep(30)

    # If 1 hour has passed, stop checking the status
    if start_time >= max_time:
        logging.info("1 hour has passed. Stopping status checks.")
        break


ssh_tunnel.stop()
