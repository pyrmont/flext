var Action = function() {};

Action.prototype = {

getElementToModify: function() {
    let element = document.activeElement;
    
    if (!element.value) {
        let longest = null;
        const textareas = document.getElementsByTagName('textarea');
        
        for (const textarea of textareas) {
            if (longest == null) {
                longest = textarea;
                continue;
            }
            
            if (!this.inViewport(textarea)) {
                continue;
            }
            
            if (textarea.value) {
                if (!longest.value) {
                    longest = textarea;
                } else if (longest.value.length < textarea.value.length) {
                    longest = textarea;
                }
            }
        }
        
        element = longest;
    }
    
    return element;
},

inViewport: function(element) {
    const rect = element.getBoundingClientRect();
    const height = window.innerHeight;
    const width = window.innerWidth;
    
    const topInside = (rect.top >= 0 && rect.top <= height);
    const bottomInside = (rect.bottom >= 0 && rect.bottom <= height);
    const leftInside = (rect.left >= 0 && rect.left <= width);
    const rightInside = (rect.right >= 0 && rect.right <= width);
    
    return (topInside && (leftInside || rightInside)) || (bottomInside && (leftInside || rightInside));
},
    
run: function(parameters) {
    let element = this.getElementToModify();
    if (element.value) {
        parameters.completionFunction({"text": element.value});
    }
},

finalize: function(parameters) {
    if (parameters["text"]) {
        let element = this.getElementToModify();
        element.value = parameters["text"];
    }
}

};

var ExtensionPreprocessingJS = new Action;
