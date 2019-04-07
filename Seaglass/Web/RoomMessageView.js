const h = preact.h;

// the array of events we want to show in the timeline, as a naughty global
const timeline = [];

// lifted directly from
// https://github.com/matrix-org/matrix-react-sdk/blob/develop/src/HtmlUtils.js
const PERMITTED_URL_SCHEMES = ['http', 'https', 'ftp', 'mailto', 'magnet'];

const sanitizeHtmlParams = {
    allowedTags: [
        'font', // custom to matrix for IRC-style font coloring
        'del', // for markdown
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'p', 'a', 'ul', 'ol', 'sup', 'sub',
        'nl', 'li', 'b', 'i', 'u', 'strong', 'em', 'strike', 'code', 'hr', 'br', 'div',
        'table', 'thead', 'caption', 'tbody', 'tr', 'th', 'td', 'pre', 'span', 'img',
    ],
    allowedAttributes: {
        // custom ones first:
        font: ['color', 'data-mx-bg-color', 'data-mx-color', 'style'], // custom to matrix
        span: ['data-mx-bg-color', 'data-mx-color', 'style'], // custom to matrix
        a: ['href', 'name', 'target', 'rel'], // remote target: custom to matrix
        img: ['src', 'width', 'height', 'alt', 'title'],
        ol: ['start'],
        code: ['class'], // We don't actually allow all classes, we filter them in transformTags
    },

    // Lots of these won't come up by default because we don't allow them
    selfClosing: ['img', 'br', 'hr', 'area', 'base', 'basefont', 'input', 'link', 'meta'],
    
    // URL schemes we permit
    allowedSchemes: PERMITTED_URL_SCHEMES,
    
    allowProtocolRelative: false,
    
    // XXX: need to port over transformTags
};

class Message extends preact.Component {
    render() {
        const ev = this.props.event;
        
        let body;
        if (ev.content.format === 'org.matrix.custom.html') {
            const html = sanitizeHtml(ev.content.formatted_body, sanitizeHtmlParams);
            body = h('div', { className: "body", dangerouslySetInnerHTML: { "__html" : html }});
        }
        else {
            body = h('div', { className: "body" }, ev.content.body );
        }
        
        return (
            h('tr', { key: ev.eventId }, [
                h('td', { className: "avatar" }, "[ :-) ]" ),
                h('td', { className: "content" }, [
                    h('div', { className: "sender" }, ev.sender ),
                    body,
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

function replaceEvent(event) {
    for (const ev of events) {
        // TODO: rather than finding, we could try to track a eventId->index map
        // but it's not obvious that the hassle of maintaining this map with
        // accurate indexes is worth it
        const i = timeline.findIndex(e => e.eventId === ev.eventId);
        timeline[i] = ev;
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
