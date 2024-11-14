## Table of Contents
1. [Description](#1-description)
2. [Requirements](#2-requirements)
3. [Setup](#3-setup)
4. [Manual Refresh Instructions](#4-manual-refresh-instructions)
5. (TBC) [Automatic Script Refresh Instructions](#5-automatic-script-refresh-instructions)

## 1 Description

Guide for Okebet to refresh PowerBI data.

## 2 Requirements

- Windows OS to install the PowerBI on-premises data gateway
- `okebet-replication.pem` ssh key

### 2.1 Automatic Script Requirements (TBC)
- Python
	- For Windows, you can install Python from [Python Releases for Windows](https://www.python.org/downloads/windows/)
- completed.env file

## 3 Setup

All instructions within this Setup section are required regardless of if you're performing manual refreshes or using the scripts.

### 3.1 Set up On-premises Data Gateway

Download Data Gateway and install.

![Data Gateway Installation](<assets/Pasted image 20241111152141.png>)

![Data Gateway Installation](<assets/Pasted image 20241111152221.png>)

Install the data gateway by signing into your Okebet Microsoft Power BI account.

Create a new on-premises data gateway, it will ask you for a gateway name and some other information.

Check to see if it's working by going here:

![Gateway Status](<assets/Pasted image 20241111152508.png>)

![Gateway Status](<assets/Pasted image 20241111152644.png>)

Your gateway will appear as Online while your computer is on, meaning it's working and we can refresh the data.

Open the settings panel for the gateway and activate the options under General and PowerBI  
![Gateway Settings](<assets/Pasted image 20241111153338.png>)

![Gateway Settings](<assets/Pasted image 20241111153353.png>)

### 3.2 Set up Connection Dataset

While still in Manage Connections and Gateways go to the 'Connections' tab and click 'New' in the top left corner.

Set up a new On-premises connection using the Gateway cluster name you created when setting up the gateway.

Name the connection and set the Connection type to MySQL.

![Connection Setup](<assets/Pasted image 20241111153634.png>)

Now fill out the following information in the remaining fields

```
Server: localhost:3309  
Database: bi

Authentication method: Basic  
Username: reporting  
Password: OnAreCleTION

Encrypted connection: Not encrypted  
Privacy level: Organizational
```

When you click Create it will test the connection and ensure the details and password are correct.

### 3.3 Connect to the Semantic Model

Now we need to connect the data to our semantic model.

Head back to the home page on PowerBI and search for Okebet Reporting, find the one that's Type Semantic Model and click it.

![Semantic Model](<assets/Pasted image 20241111154425.png>)

Within the semantic model click File > Settings:

![Semantic Model Settings](<assets/Pasted image 20241111154457.png>)

Now expand the "Gateway and cloud connections" dropdown and you'll see some information about the data sources included in the semantic model. We want to map the MySQL server to the Connection we created earlier, which we called bm. Once you map it correctly it will look like this:

![Mapped Connection](<assets/Pasted image 20241114143835.png>)

Maps to: bm

Click Apply to save the settings.

## 4 Manual Refresh Instructions

For our refresh to work we have to be connected to the ssh tunnel provided by BetMakers.

The following instructions are specifically for Windows PCs because you must open the ssh tunnel on the PC where you installed the on-premises gateway.

Take the private key certificate provided (okebet-replication.pem) and place it somewhere easily accessible e.g. your desktop.

![Private Key Certificate](<assets/Pasted image 20241114152423.png>)

Now we need to run a terminal command that uses this certificate.

The easiest way to do this if you're unfamiliar with how terminals work is to ensure you have Windows' new 'Terminal' program, which provides a handy right click option.

Right click your desktop (or any folder where you placed the certificate) and select 'Open in Terminal'. If you don't see this option I recommend just heading to the Microsoft Store on your PC and installing it.

![Open in Terminal](<assets/Pasted image 20241114152505.png>)

Once the Terminal opens you'll see it opens to wherever you right clicked from:

![Terminal](<assets/Pasted image 20241114152531.png>)

We can make sure of this by running the 'ls' command (meaning list) which will display all the contents of the folder that the terminal is in. We can see the certificate file when running the list command on the Desktop:

![List Command](<assets/Pasted image 20241114152641.png>)

Now we can run the ssh command to connect. Copy this and run it.

```copy
ssh -i okebet-replication.pem bm@54.79.64.88 -L 3309:replicated-db-api.okebet.com.au:3306 -N
```

If it's the first time you've run it you may see a security prompt that requires you to type 'yes'.

Once run successfully you'll see it look like this, with a simple blinking cursor:

![SSH Connection](<assets/Pasted image 20241114152800.png>)

Now that the ssh is connected let's head back to PowerBI online and try to refresh the data. (The refresh can be performed from any computer as long as the Windows machine with the gateway installed is connected to the ssh tunnel)

Back on the Okebet Reporting settings page we were on earlier. Let's click Refresh > Refresh now:

![Refresh Now](<assets/Pasted image 20241114152932.png>)

You'll see a small animated circle indicating the refresh is taking place.

![Refresh In Progress](<assets/Pasted image 20241114153019.png>)

For more information about the refresh you can head to Refresh > Refresh history and see the following screen showing how we have a refresh currently in progress and all the past refreshes completed. Detailed error messages may also appear here if things go wrong.

![Refresh History](<assets/Pasted image 20241114153148.png>)

In my experience, the refresh should take approximately 6-8 mins.

Once the refresh finishes the small animated circle will stop spinning. If you refresh the settings page you'll see the time of the last refresh has updated:

![Refresh Completed](<assets/Pasted image 20241114153747.png>)

Inside the history we can also see that it's completed and it took about 6 minutes:

![Refresh History Completed](<assets/Pasted image 20241114153821.png>)

We're done! That's how you can perform a manual refresh of the dataset.

## 5 Automatic Script Refresh Instructions

To be completed.
