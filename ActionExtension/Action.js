var Action = function() {};

Action.prototype = {

run: function(parameters) {
    var text = document.activeElement.value;
    parameters.completionFunction({"text": text});
},

finalize: function(parameters) {
    if (parameters["text"]) {
        var el = document.activeElement
        if (el) {
            el.value = parameters["text"]
        }
    }
}

};

var ExtensionPreprocessingJS = new Action
