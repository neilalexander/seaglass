const h = preact.h;

// the array of events we want to show in the timeline, as a naughty global
const timeline = [];

// all the sanitsation stuff is stolen from
// https://github.com/matrix-org/matrix-react-sdk/blob/develop/src/HtmlUtils.js
const PERMITTED_URL_SCHEMES = ['http', 'https', 'ftp', 'mailto', 'magnet'];
const COLOR_REGEX = /^#[0-9a-fA-F]{6}$/;

const transformTags = { // custom to matrix
    // add blank targets to all hyperlinks
    'a': function(tagName, attribs) {
        if (attribs.href) {
            attribs.target = '_blank'; // by default

            // TODO: handle matrix.to URLs specially here
        }
        attribs.rel = 'noopener'; // https://mathiasbynens.github.io/rel-noopener/
        return { tagName, attribs };
    },
    'img': function(tagName, attribs) {
        // Strip out imgs that aren't `mxc` here instead of using allowedSchemesByTag
        // because transformTags is used _before_ we filter by allowedSchemesByTag and
        // we don't want to allow images with `https?` `src`s.
        if (!attribs.src || !attribs.src.startsWith('mxc://')) {
            return { tagName, attribs: {}};
        }
        // todo: handle inline images here
        /*
        attribs.src = MatrixClientPeg.get().mxcUrlToHttp(
                                                         attribs.src,
                                                         attribs.width || 800,
                                                         attribs.height || 600,
                                                         );
         */
        return { tagName, attribs };
    },
    '*': function(tagName, attribs) {
        // Delete any style previously assigned, style is an allowedTag for font and span
        // because attributes are stripped after transforming
        delete attribs.style;
        
        // Sanitise and transform data-mx-color and data-mx-bg-color to their CSS
        // equivalents
        const customCSSMapper = {
            'data-mx-color': 'color',
            'data-mx-bg-color': 'background-color',
        };
        
        let style = "";
        Object.keys(customCSSMapper).forEach((customAttributeKey) => {
             const cssAttributeKey = customCSSMapper[customAttributeKey];
             const customAttributeValue = attribs[customAttributeKey];
             if (customAttributeValue &&
                 typeof customAttributeValue === 'string' &&
                 COLOR_REGEX.test(customAttributeValue))
             {
                 style += cssAttributeKey + ":" + customAttributeValue + ";";
                 delete attribs[customAttributeKey];
             }
        });
        
        if (style) {
            attribs.style = style;
        }
        
        return { tagName, attribs };
    },
};

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
    transformTags,
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
