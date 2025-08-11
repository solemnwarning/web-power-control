var UPDATE_INTERVAL = 1000;

var power_status_elem;
var power_on_button;
var soft_off_button;
var hard_off_button;
var reset_button;
var events_elem;
var update_timeout;

function update()
{
	if(update_timeout !== undefined)
	{
		clearTimeout(update_timeout);
	}
	
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function() {
		if (this.readyState == 4) {
			if(this.status == 200)
			{
				var json = JSON.parse(xhttp.responseText);
				
				if(json["power-on"])
				{
					power_status_elem.innerHTML = "Powered <span class=\"on\">on</span>";
				}
				else{
					power_status_elem.innerHTML = "Powered <span class=\"off\">off</span>";
				}
				
				power_on_button.disabled = json["power-on"];
				soft_off_button.disabled = !(json["power-on"]);
				hard_off_button.disabled = !(json["power-on"]);
				reset_button.disabled = !(json["power-on"]);
				
				/* Insert any new events to the front of the events list */
				
				for(var i = 0; i < json.events.length; ++i)
				{
					var serial = json.events[i][0];
					var timestamp = json.events[i][1];
					var text = json.events[i][2];
					
					var date = new Date(timestamp * 1000);
					
					var event_node = document.createElement("li");
					
					event_node.classList.add("serial-" + serial);
					event_node.appendChild(document.createTextNode("[" + date.toLocaleString() + "] " + text));
					
					/* Scan the events list to see if the event is already there. */
					
					var found = false;
					
					for(var j = 0; j < events_elem.childNodes.length; ++j)
					{
						if(events_elem.childNodes[j].isEqualNode(event_node))
						{
							found = true;
							break;
						}
					}
					
					if(!found)
					{
						events_elem.insertBefore(event_node, events_elem.firstChild);
					}
				}
			}
			else{
				power_status_elem.innerHTML = "Unknown";
			}
			
			update_timeout = setTimeout(update, UPDATE_INTERVAL);
		}
	};
	
	xhttp.open("GET", "/status", true);
	xhttp.send();
}

function post(url, desc)
{
	power_status_elem.innerHTML = desc;
	
	power_on_button.disabled = true;
	soft_off_button.disabled = true;
	hard_off_button.disabled = true;
	reset_button.disabled = true;
	
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function()
	{
		if (this.readyState == 4)
		{
			update();
		}
	};
	xhttp.open("POST", url, true);
	xhttp.send();
}

document.addEventListener("DOMContentLoaded", (event) => {
	power_status_elem = document.getElementById("power-status");
	power_on_button = document.getElementById("power-on");
	soft_off_button = document.getElementById("soft-off");
	hard_off_button = document.getElementById("hard-off");
	reset_button = document.getElementById("reset");
	events_elem = document.getElementById("events");
	
	update();
});
