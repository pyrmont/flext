var process = function(text) {
    var result = ""
    var should_capitalise = true
    
    for (const char of text) {
        result = result + (should_capitalise ? char.toUpperCase() : char)
        should_capitalise = (char == " ") ? true : false
    }
    
    return result
}
