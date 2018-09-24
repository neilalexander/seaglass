window.onerror = function(error) {
    alert(error);
};

function removeEvents(events) {
    let timeline = document.getElementById("timeline");
    
    for (const ev of events) {
        document.getElementById(ev.eventId).remove();
    }
}

function drawEvents(events, append) {
    let timeline = document.getElementById("timeline");
    
    for (const ev of events) {
        const tile = document.createElement("tr");
        tile.id = ev.eventId
        
        switch (ev.type) {
            case "m.room.message":
                avatar = document.createElement("td");
                avatar.className = "avatar";
                avatar.innerHTML = "[ :-) ]";
                
                content = document.createElement("td");
                content.className = "content";
                
                sender = document.createElement("div");
                sender.className = "sender";
                sender.innerHTML = ev.sender;
                content.appendChild(sender);
                
                body = document.createElement("div");
                body.className = "body";
                body.innerHTML = ev.content.formatted_body || event.content.body;
                content.appendChild(body);
                
                timestamp = document.createElement("td");
                timestamp.className = "timestamp";
                timestamp.innerHTML = "00:00";
                
                tile.appendChild(avatar);
                tile.appendChild(content);
                tile.appendChild(timestamp);
                break
                
            default:
                avatar = document.createElement("td");
                avatar.className = "avatar";
                
                content = document.createElement("td");
                content.className = "content";
                
                body = document.createElement("div");
                body.className = "inline";
                body.innerHTML = "No event handler for " + ev.type;
                content.appendChild(body);
                
                timestamp = document.createElement("td");
                timestamp.className = "timestamp";
                
                tile.appendChild(avatar);
                tile.appendChild(content);
                tile.appendChild(timestamp);
                break
        }
        
        if (append) {
            timeline.appendChild(tile);
        } else {
            timeline.insertBefore(tile, timeline.firstChild);
        }
    }
}
