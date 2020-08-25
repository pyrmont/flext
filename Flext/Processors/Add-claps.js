var process = function(text) {
    const clap = "\uD83D\uDC4F"
    var result = ""
    
    for (const char of text) {
        result = result + char + (char == " " ? clap + char : "")
    }

    return result
}
