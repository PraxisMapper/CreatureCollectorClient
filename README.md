# CreatureCollectorClient
The source code for The Immortal Battle for Ohio, free.

![image](https://user-images.githubusercontent.com/114430030/203230013-3863d461-1972-4b11-9ec1-db282a6f8b3a.png)
![image](https://user-images.githubusercontent.com/114430030/203230164-9353d677-9f1a-4e59-b367-6e0c41559dc9.png)

# Setup
* Have a PraxisMapper instance setup and running. See the documentation on the PraxisMapper repo for details.
* Copy the PraxisCreatureCollectorPlugin DLL to the plugins folder in PraxisMapper, then restart the server, hit the /Creature/Test endpoint, and restart the server again to make sure all initialization stuff has been done server-side.
* Install Solar2D on your computer
* Get the source code for this app
* Edit gameSettings.lua with the important bits of info
* * Set serverURL to the URL of your server when the game is running on a device. This usually requires an SSL connection.
* * Set serverSimulatorURL to the URL to use when you're in the Solar2D Simulator enviroment. This is usually expected to be localhost on a dev server, but could be a live server with SSL.
* * If you have enableHeaderCheck set to true in PraxisMappper, change headerAuthKey here to match serverAuthKey in your PraxisMapper appsettings.json file
* * (Optional) set locationName to the name of the area you're covering in your server.
* * (Optional) set your 4 default ProxyPlay points with a name, description and 10-digit PlusCode, leaving out the +. 

# Licensing
The code presented here (settings and .lua files) are under the MIT license.
Graphics are released under a CC BY-SA 4.0 license.
