var Action = function() {};

Action.prototype = {

run: function(parameters) {
    let text = document.activeElement.value;
    
    if (!text) {
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
        
        text = longest.value;
    }
    
    parameters.completionFunction({"text": text});
},

finalize: function(parameters) {
    if (parameters["text"]) {
        let el = document.activeElement;
        if (!el.value) {
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
            
            el = longest;
        }
        
        el.value = parameters["text"];
    }
}

};

var ExtensionPreprocessingJS = new Action
