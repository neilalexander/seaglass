const h = preact.h;

// the array of events we want to show in the timeline, as a naughty global
const timeline = [];

class Message extends preact.Component {
    render() {
        const ev = this.props.event;
        return (
            h('tr', { key: ev.eventId }, [
                h('td', { className: "avatar" }, "[ :-) ]" ),
                h('td', { className: "content" }, [
                    h('div', { className: "sender" }, ev.sender ),
                    h('div', { className: "body" },   ev.content.formatted_body || ev.content.body ),
                ]),
                h('td', { className: "timestamp" }, "00:00" ),
            ])
        );
    }
}

class EncryptedMessage extends preact.Component {
    render() {
        const ev = this.props.event;
        return (
            h('tr', { key: ev.eventId }, [
                h('td', { className: "avatar" }, "[ :-) ]" ),
                h('td', { className: "content" }, [
                    h('div', { className: "sender" }, ev.sender ),
                    h('div', { className: "body" },   ev.content.formatted_body || ev.content.body ),
                ]),
                h('td', { className: "timestamp" }, "00:00" ),
            ])
        );
    }
}

class UnknownEvent extends preact.Component {
    render() {
        const ev = this.props.event;
        return (
            h('tr', { key: ev.eventId }, [
                h('td', { className: "avatar" }, null ),
                h('td', { className: "content" }, [
                    h('div', { className: "inline" }, `No event handler for ${ev.type}` ),
                ]),
                h('td', { className: "timestamp" }, "00:00" ),
            ])
        );
    }
}

class Timeline extends preact.Component {
    render() {
        return (
            h('table', { id: "timeline" },
                this.props.timeline.map((event)=>{
                    switch (event.type) {
                        case "m.room.message":
                            return h(Message, { event });
                        default:
                            return h(UnknownEvent, { event });
                    }
                })
            )
        );
    }
}

window.onerror = function(error) {
    alert(error);
};

function removeEvents(events) {
    // XXX: why would you ever need to remove a specific event?
    // surely the common case is to replace all the events in the
    // table with a new set of events, which can be done more quickly
    // than going through deleting the old ones first...

    for (const ev of events) {
        const i = timeline.indexOf(ev.eventId);
        timeline.splice(i, 1);
    }

    preact.render(h(Timeline, { timeline }), document.body, document.body.lastChild);
}

function drawEvents(events, append) {
    for (const ev of events) {
        if (append) {
            timeline.push(ev);
        }
        else {
            timeline.unshift(ev);
        }
    }

    preact.render(h(Timeline, { timeline }), document.body, document.body.lastChild);
}
