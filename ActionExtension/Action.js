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
